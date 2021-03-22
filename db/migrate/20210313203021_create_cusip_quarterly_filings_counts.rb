class CreateCusipQuarterlyFilingsCounts < ActiveRecord::Migration[6.1]
  def up
    create_view :cusip_quarterly_filings_counts, materialized: true

    add_index :cusip_quarterly_filings_counts,
      %i(cusip report_year report_quarter),
      unique: true,
      name: "index_cusip_quarterly_filings_unique"
  end

  def down
    drop_view :cusip_quarterly_filings_counts, materialized: true
  end
end
