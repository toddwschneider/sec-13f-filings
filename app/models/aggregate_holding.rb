class AggregateHolding < ApplicationRecord
  belongs_to :thirteen_f

  belongs_to :thirteen_f_with_minimal_fields,
    -> { select(:id, :name, :report_date, :external_id, :cik, :report_quarter, :report_year, :amendment_type) },
    class_name: "ThirteenF",
    foreign_key: :thirteen_f_id

  scope :descend_by_value, -> { order("value DESC, lower(issuer_name)") }

  scope :all_cusip_holdings, -> (cusip, year, quarter) {
    subselect = ThirteenF.
      select(:id).
      where(report_year: year, report_quarter: quarter).
      exclude_restated

    where(cusip: cusip, thirteen_f_id: subselect).
      includes(thirteen_f_with_minimal_fields: :filer).
      order(shares_or_principal_amount: :desc)
  }

  scope :manager_cusip_holdings, -> (cusip, manager_cik) {
    joins(:thirteen_f).
      select("
        aggregate_holdings.*,
        thirteen_fs.report_date, thirteen_fs.external_id, thirteen_fs.date_filed,
        thirteen_fs.report_quarter, thirteen_fs.report_year, thirteen_fs.name,
        thirteen_fs.holdings_value_calculated, thirteen_fs.amendment_type
      ").
      where(aggregate_holdings: {cusip: cusip}).
      where(thirteen_fs: {cik: manager_cik, restated_by_id: nil}).
      order("thirteen_fs.report_date DESC, thirteen_fs.date_filed DESC, thirteen_fs.id DESC")
  }

  def equity?
    shares_or_principal_amount_type == "sh"
  end

  def debt?
    shares_or_principal_amount_type == "prn"
  end

  def shares
    shares_or_principal_amount if equity?
  end

  def principal
    shares_or_principal_amount if debt?
  end

  def value_per_share
    return unless equity? && shares.to_i > 0
    1000 * value / shares
  end
end
