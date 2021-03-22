class ThirteenF < ApplicationRecord
  COLUMN_NAMES_WITHOUT_XML = column_names.reject { |n| n.end_with?("_xml") }
  FIRST_YEAR_EXPECTED_TO_HAVE_XML_URLS = 2014

  has_many :holdings, dependent: :destroy
  has_many :aggregate_holdings, dependent: :destroy

  belongs_to :filer,
    class_name: "ThirteenFFiler",
    primary_key: :cik,
    foreign_key: :cik

  scope :most_recent, -> { order(report_date: :desc, date_filed: :desc, holdings_value_calculated: :desc) }
  scope :name_starts, ->(q) { where("name ILIKE ?", "#{q}%") }
  scope :name_matches, ->(q) { where("name ILIKE ?", "%#{q}%") }

  scope :unprocessed, -> { where(xml_data_fetched_at: nil) }
  scope :processed, -> { where.not(xml_data_fetched_at: nil) }
  scope :without_xml_fields, -> { select(COLUMN_NAMES_WITHOUT_XML) }
  scope :exclude_restated, -> { where(restated_by_id: nil) }

  scope :newest_filings_since, ->(date) {
    where("date_filed >= ?", date).order(date_filed: :desc, id: :desc)
  }

  def previous_filings
    self.class.
      processed.
      exclude_restated.
      where(cik: cik).
      where("report_date < ?", report_date).
      order(report_date: :desc, holdings_value_calculated: :desc)
  end

  def future_filings
    self.class.
      processed.
      exclude_restated.
      where(cik: cik).
      where("report_date > ?", report_date).
      order(:report_date, holdings_value_calculated: :desc)
  end

  def comparison_candidates
    self.class.
      processed.
      exclude_restated.
      where(cik: cik).
      where.not(id: id).
      select(:id, :external_id, :report_date, :report_year, :report_quarter, :amendment_type).
      most_recent
  end

  def self.import_filings!(filing_year:, filing_quarter:)
    now = Time.zone.now

    rows = client.thirteen_f_filings(filing_year: filing_year, filing_quarter: filing_quarter).map do |row|
      {
        external_id: row.external_id,
        cik: row.cik,
        name: row.company_name,
        form_type: row.form_type,
        date_filed: row.date_filed,
        directory_url: row.directory_url,
        filing_year: filing_year,
        filing_quarter: filing_quarter,
        created_at: now,
        updated_at: now
      }
    end

    return if rows.blank?

    insert_all(rows, returning: false)
    ThirteenFFiler.refresh!
  end

  def self.import_most_recent_filings!(filed_since: Date.yesterday)
    now = Time.zone.now

    rows = client.latest_thirteen_f_filings(filed_since: filed_since.to_date).map do |row|
      {
        external_id: row.external_id,
        cik: row.cik,
        name: row.company_name,
        form_type: row.form_type,
        date_filed: row.date_filed,
        directory_url: row.directory_url,
        filing_year: row.date_filed.year,
        filing_quarter: (row.date_filed.month - 1) / 3 + 1,
        created_at: now,
        updated_at: now
      }
    end

    return if rows.blank?

    insert_all(rows, returning: false)
    ThirteenFFiler.refresh!
  end

  def self.process_unprocessed_filings!(filing_year: nil, filing_quarter: nil, name_starts: nil, ciks: nil, refresh_views: true)
    scoped = unprocessed
    scoped = scoped.where(filing_year: filing_year) if filing_year
    scoped = scoped.where(filing_quarter: filing_quarter) if filing_quarter
    scoped = scoped.name_starts(name_starts) if name_starts
    scoped = scoped.where(cik: ciks) if ciks

    scoped.find_each do |f|
      f.delay.process!
    end

    if refresh_views
      ThirteenFFiler.delay(priority: 10).refresh!
      CompanyCusipLookup.delay(priority: 10).refresh!
    end
  end

  # delayed_job does not support named args in ruby 3 yet
  # see: https://github.com/collectiveidea/delayed_job/issues/1134
  def self.import_and_process_filings!(filing_year, filing_quarter)
    import_filings!(filing_year: filing_year, filing_quarter: filing_quarter)
    process_unprocessed_filings!(filing_year: filing_year, filing_quarter: filing_quarter)
  end

  def self.import_and_process_most_recent_filings!
    import_most_recent_filings!

    process_unprocessed_filings!(
      filing_year: Date.today.year,
      filing_quarter: (Date.today.month - 1) / 3 + 1,
      refresh_views: false
    )
  end

  def process!(force: false)
    return unless unprocessed? || force

    cache_xml_data
    cache_attributes_from_primary_doc
    create_holdings
  end

  def cache_xml_data
    self.primary_doc_url = client.primary_doc_url(xml_urls)
    self.primary_doc_xml = HTTParty.get(primary_doc_url).body if primary_doc_url
    self.info_table_url = client.info_table_url(xml_urls)
    self.info_table_xml = HTTParty.get(info_table_url).body if info_table_url
    self.xml_data_fetched_at = Time.zone.now

    save!
  rescue SecClient::XmlUrlsNotFound
    raise if expected_to_have_xml_urls?
  end

  def processed?
    xml_data_fetched_at.present?
  end

  def unprocessed?
    !processed?
  end

  def expected_to_have_xml_urls?
    filing_year >= FIRST_YEAR_EXPECTED_TO_HAVE_XML_URLS
  end

  def cache_attributes_from_primary_doc
    return if xml_data_fetched_at.blank?

    self.report_date = parsed_primary_doc.report_date
    self.report_year = report_date.year
    self.report_quarter = (report_date.month - 1) / 3 + 1
    self.street1 = parsed_primary_doc.street1
    self.street2 = parsed_primary_doc.street2
    self.city = parsed_primary_doc.city
    self.state_or_country = parsed_primary_doc.state_or_country
    self.zip_code = parsed_primary_doc.zip_code
    self.other_included_managers_count = parsed_primary_doc.other_included_managers_count
    self.holdings_count_reported = parsed_primary_doc.holdings_count_reported
    self.holdings_value_reported = parsed_primary_doc.holdings_value_reported
    self.confidential_omitted = parsed_primary_doc.confidential_omitted
    self.other_managers = parsed_primary_doc.other_managers
    self.report_type = parsed_primary_doc.report_type
    self.amendment_type = parsed_primary_doc.amendment_type
    self.amendment_number = parsed_primary_doc.amendment_number
    self.file_number = parsed_primary_doc.file_number

    save!

    mark_previous_filings_as_restated if is_restatement?
  end

  def is_restatement?
    amendment_type == "restatement"
  end

  def has_been_restated?
    restated_by_id.present?
  end

  def restated_by_filing
    return unless has_been_restated?

    self.class.
      without_xml_fields.
      find(restated_by_id)
  end

  def mark_previous_filings_as_restated
    return unless is_restatement?

    scoped = self.class.
      where(cik: cik, report_date: report_date).
      where.not(id: id).
      where("date_filed <= ?", date_filed).
      where("amendment_type IS NULL OR (amendment_type = 'restatement' AND amendment_number < ?)", amendment_number)

    scoped.find_each do |f|
      f.restated_by_id = id
      f.save!
    end
  end

  def has_no_info_table?
    xml_data_fetched_at.present? && info_table_url.blank?
  end

  def create_holdings
    return if xml_data_fetched_at.blank? || has_no_info_table?

    now = Time.zone.now
    additional_cols = {thirteen_f_id: id, created_at: now, updated_at: now}
    rows = parsed_info_table.map { |r| r.merge(additional_cols) }

    aggregate_query = <<-SQL
      INSERT INTO aggregate_holdings (
        thirteen_f_id, cusip, issuer_name, class_title, value, shares_or_principal_amount,
        shares_or_principal_amount_type, option_type, voting_authority_sole,
        voting_authority_shared, voting_authority_none, created_at, updated_at
      )
      SELECT
        thirteen_f_id,
        cusip,
        issuer_name,
        class_title,
        sum(value) AS value,
        sum(shares_or_principal_amount) AS shares_or_principal_amount,
        shares_or_principal_amount_type,
        option_type,
        sum(voting_authority_sole) AS voting_authority_sole,
        sum(voting_authority_shared) AS voting_authority_shared,
        sum(voting_authority_none) AS voting_authority_none,
        :now AS created_at,
        :now AS updated_at
      FROM holdings
      WHERE thirteen_f_id = :id
      GROUP BY thirteen_f_id, cusip, issuer_name, class_title, shares_or_principal_amount_type, option_type
    SQL

    transaction do
      holdings.delete_all
      Holding.insert_all(rows, returning: false)

      aggregate_holdings.delete_all
      self.class.find_by_sql([aggregate_query, id: id, now: now])
    end

    self.holdings_count_calculated = rows.size
    self.holdings_value_calculated = rows.map(&:value).compact.sum
    self.aggregate_holdings_count = aggregate_holdings.count
    save!
  end

  def full_submission_url
    final_path = [
      external_id[0..9],
      external_id[10..11],
      external_id[12..-1]
    ].join("-")

    "#{directory_url.chomp("/")}/#{final_path}.txt"
  end

  def sec_index_url
    full_submission_url.sub(/\.txt\z/, "-index.html")
  end

  def city_and_state
    [city&.titleize, state_or_country].compact.join(", ")
  end

  def form_and_amendment_type
    [form_type, amendment_type].compact.join(" - ")
  end

  def form_or_amendment_type
    amendment_type.presence || form_type
  end

  def yyyy_qq
    return unless report_date.present?
    "#{report_year} Q#{report_quarter}"
  end

  def qq_yyyy
    return unless report_date.present?
    "Q#{report_quarter} #{report_year}"
  end

  def self.to_param(external_id, name, quarter, year, amendment_type)
    [
      external_id,
      name,
      ("Q#{quarter}" if quarter),
      year,
      amendment_type
    ].compact.join(" ").parameterize
  end

  def to_param
    self.class.to_param(
      external_id,
      name,
      report_quarter,
      report_year,
      amendment_type
    )
  end

  def self.find_by_param!(param)
    find_by!(external_id: param.split("-").first)
  end

  def parsed_primary_doc
    return unless primary_doc_xml.present?
    @parsed_primary_doc ||= client.parse_primary_doc_xml(primary_doc_xml)
  end

  def parsed_info_table
    return unless info_table_xml.present?
    @parsed_info_table ||= client.parse_info_table_xml(info_table_xml)
  end

  def xml_urls
    @xml_urls ||= client.xml_urls(directory_url)
  end
end
