class CusipQuarterlyFilingsCount < ApplicationRecord
  def readonly?
    true
  end

  scope :for_cusip_index, ->(cusip) {
    where(cusip: cusip).
      where("report_year >= ?", ThirteenF::FIRST_YEAR_EXPECTED_TO_HAVE_XML_URLS).
      order(report_year: :desc, report_quarter: :desc)
  }

  def self.refresh!
    Scenic.database.refresh_materialized_view(
      :cusip_quarterly_filings_counts,
      concurrently: true
    )
  end

  def yyyy_qq
    "#{report_year} Q#{report_quarter}"
  end
end
