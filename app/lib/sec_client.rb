class SecClient
  BASE_URL = "https://www.sec.gov"
  EXPECTED_COL_NAMES = %i(cik company_name form_type date_filed filename)
  THIRTEEN_F_FORM_TYPES = %w(13F-HR 13F-HR/A)

  RateLimited = Class.new(StandardError)
  XmlUrlsNotFound = Class.new(StandardError)

  def thirteen_f_filings(filing_year:, filing_quarter:, delete_tmpfile: true)
    url = "#{BASE_URL}/Archives/edgar/full-index/#{filing_year}/QTR#{filing_quarter}/master.idx"

    filename = Rails.root.join(
      "tmp",
      "sec_daily_index_files",
      filing_year.to_s,
      "QTR#{filing_quarter}",
      "master.idx"
    )

    FileUtils.mkdir_p(File.dirname(filename))
    Down.download(url, destination: filename, headers: request_headers)

    thirteen_fs = []
    col_names = nil

    IO.foreach(filename) do |raw_line|
      line = raw_line.
        encode("UTF-8", invalid: :replace, undef: :replace, replace: "?").
        strip.
        split("|")

      next unless line.size == EXPECTED_COL_NAMES.size

      if col_names.blank?
        col_names = line.map { |n| n.downcase.gsub(" ", "_").to_sym }
        raise "Unexpected column names" unless col_names == EXPECTED_COL_NAMES
        next
      end

      row = col_names.zip(line).to_h

      next unless THIRTEEN_F_FORM_TYPES.include?(row.fetch(:form_type))

      full_submission_url = "#{BASE_URL}/Archives/#{row.fetch(:filename)}"
      dir_url = full_submission_url.chomp(".txt").gsub("-", "")

      thirteen_fs << Hashie::Mash.new({
        external_id: dir_url.split("/").last,
        company_name: row.fetch(:company_name),
        form_type: row.fetch(:form_type).upcase,
        cik: padded_cik(row.fetch(:cik)),
        date_filed: row.fetch(:date_filed).to_date,
        full_submission_url: full_submission_url,
        directory_url: dir_url
      })
    end

    File.delete(filename) if delete_tmpfile

    thirteen_fs
  end

  def latest_thirteen_f_filings(filed_since: Date.yesterday, per_page: 100, max_pages: 100)
    url = "#{BASE_URL}/cgi-bin/browse-edgar"

    query_params = {
      action: "getcurrent",
      count: per_page,
      output: "atom",
      type: "13F-HR"
    }

    title_regex = /\A13F\-HR(?:\/A)? - (.+?) \((\d{10})\)/

    results = []

    max_pages.times do
      doc = Nokogiri::XML(HTTParty.get(url, query: query_params).body)

      doc.css("entry").each do |e|
        date_filed = Date.parse(e.at("updated").text)
        next if date_filed < filed_since.to_date

        directory_url = e.at("link")["href"].split("/")[0...-1].join("/")
        external_id = directory_url.split("/").last
        cik = padded_cik(directory_url.split("/")[-2])
        form_type = e.at("category[label='form type']")["term"]
        company_name = e.at("title").text[title_regex, 1]

        results << Hashie::Mash.new({
          external_id: external_id,
          company_name: company_name,
          form_type: form_type,
          cik: cik,
          date_filed: date_filed,
          directory_url: directory_url
        })
      end

      break if doc.css("entry").size < per_page

      query_params[:start] = (query_params[:start] || 0) + per_page
    end

    results
  end

  def parse_primary_doc_xml(xml)
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    date_string = doc.at("reportCalendarOrQuarter").text.squish

    other_managers = doc.css("otherManagers2Info otherManager2").map do |o|
      {
        sequence_number: o.at("sequenceNumber")&.text&.to_i,
        file_number: o.at("form13FFileNumber")&.text&.squish,
        name: o.at("name")&.text&.squish
      }
    end

    Hashie::Mash.new({
      report_date: Date.strptime(date_string, "%m-%d-%Y"),
      street1: doc.at("address street1")&.text&.squish&.downcase,
      street2: doc.at("address street2")&.text&.squish&.downcase,
      city: doc.at("address city")&.text&.squish&.downcase,
      state_or_country: doc.at("address stateOrCountry")&.text&.squish&.upcase,
      zip_code: doc.at("address zipCode")&.text&.squish,
      other_included_managers_count: doc.at("otherIncludedManagersCount")&.text&.squish,
      holdings_count_reported: doc.at("tableEntryTotal")&.text&.squish,
      holdings_value_reported: doc.at("tableValueTotal")&.text&.squish,
      confidential_omitted: doc.at("isConfidentialOmitted")&.text&.squish,
      report_type: doc.at("reportType")&.text&.squish&.downcase,
      amendment_type: doc.at("amendmentType")&.text&.squish&.downcase,
      amendment_number: doc.at("amendmentNo")&.text&.to_i,
      file_number: doc.at("coverPage form13FFileNumber")&.text&.squish,
      other_managers: other_managers
    })
  end

  def parse_info_table_xml(xml)
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!

    doc.css("infoTable").map do |i|
      Hashie::Mash.new({
        cusip: i.at("cusip").text.upcase.squish.rjust(9, "0"),
        issuer_name: i.at("nameOfIssuer")&.text&.squish.presence,
        class_title: i.at("titleOfClass")&.text&.squish&.downcase.presence,
        value: parse_float(i.at("value").text),
        shares_or_principal_amount: i.at("sshPrnamt")&.text&.squish.presence,
        shares_or_principal_amount_type: i.at("sshPrnamtType")&.text&.squish&.downcase.presence,
        option_type: i.at("putCall")&.text&.squish&.downcase.presence,
        investment_discretion: i.at("investmentDiscretion")&.text&.squish&.downcase.presence,
        other_manager: i.at("otherManager")&.text&.squish.presence,
        voting_authority_sole: i.at("votingAuthority Sole")&.text&.squish.presence,
        voting_authority_shared: i.at("votingAuthority Shared")&.text&.squish.presence,
        voting_authority_none: i.at("votingAuthority None")&.text&.squish.presence
      })
    end
  end

  def xml_urls(directory_url)
    urls = Nokogiri::HTML(get(directory_url).body).
      css("#main-content a").
      map { |a| "#{BASE_URL}#{a["href"]}" }.
      select { |u| u.to_s.downcase.end_with?(".xml") }

    raise XmlUrlsNotFound if urls.blank?

    urls
  end

  def primary_doc_url(xml_urls)
    if url = xml_urls.detect { |u| u =~ /primary.*doc/i }
      return url
    end

    xml_urls.detect do |u|
      Nokogiri::XML(get(u).body).at("edgarSubmission").present?
    end
  end

  def info_table_url(xml_urls)
    if url = xml_urls.detect { |u| u =~ /info.*table/i }
      return url
    end

    xml_urls.detect do |u|
      doc = Nokogiri::XML(get(u).body)
      doc.remove_namespaces!
      doc.at("informationTable").present?
    end
  end

  def get(url)
    response = HTTParty.get(url, headers: request_headers)
    raise RateLimited if response.code == 429
    response
  end

  private

  def padded_cik(str_or_int)
    str_or_int.to_s.strip.rjust(10, "0")
  end

  def parse_float(value)
    return unless value.squish.present?
    Float(value)
  end

  def directory_url(index_url)
    index_url.
      gsub(/\-index.html?\z/i, "").
      gsub("-", "")
  end

  # https://www.sec.gov/os/webmaster-faq#code-support
  def user_agent
    if ENV["SEC_USER_AGENT"].blank?
      raise "No SEC_USER_AGENT environment variable set"
    end

    ENV["SEC_USER_AGENT"]
  end

  def request_headers
    {"User-Agent" => user_agent}
  end
end
