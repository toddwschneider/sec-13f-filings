class DataTableFormatter
  def self.thirteen_f_to_aggregated_datatable(thirteen_f)
    rows = thirteen_f.aggregate_holdings.descend_by_value.map do |h|
      if h.value
        pct_of_total = 100 * h.value.to_f / thirteen_f.holdings_value_calculated.to_f
      end

      [
        h.issuer_name,
        h.class_title.upcase,
        h.cusip,
        h.value&.to_i,
        pct_of_total&.round(1),
        h.shares&.to_i,
        h.principal&.to_i,
        h.option_type
      ]
    end

    {data: rows}
  end

  def self.thirteen_f_to_detailed_datatable(thirteen_f)
    rows = thirteen_f.holdings.descend_by_value.map do |h|
      if h.value
        pct_of_total = 100 * h.value.to_f / thirteen_f.holdings_value_calculated.to_f
      end

      [
        h.issuer_name,
        h.class_title.upcase,
        h.cusip,
        h.value&.to_i,
        pct_of_total&.round(1),
        h.shares&.to_i,
        h.principal&.to_i,
        h.option_type,
        h.investment_discretion,
        h.other_manager,
        h.voting_authority_sole&.to_i,
        h.voting_authority_shared&.to_i,
        h.voting_authority_none&.to_i
      ]
    end

    {data: rows}
  end

  def self.thirteen_f_comparison_to_datatable(filing, other_filing)
    query = <<-SQL
      WITH filing AS (
        SELECT *
        FROM aggregate_holdings
        WHERE thirteen_f_id = :id
      ),
      other_filing AS (
        SELECT *
        FROM aggregate_holdings
        WHERE thirteen_f_id = :other_id
      )
      SELECT
        coalesce(f.issuer_name, o.issuer_name) AS issuer_name,
        coalesce(f.class_title, o.class_title) AS class_title,
        coalesce(f.cusip, o.cusip) AS cusip,
        coalesce(f.shares_or_principal_amount_type, o.shares_or_principal_amount_type) AS shares_or_principal_amount_type,
        coalesce(f.option_type, o.option_type) AS option_type,
        coalesce(f.value, 0) AS value,
        coalesce(o.value, 0) AS other_value,
        coalesce(f.shares_or_principal_amount, 0) AS shares_or_principal_amount,
        coalesce(o.shares_or_principal_amount, 0) AS other_shares_or_principal_amount
      FROM filing f
        FULL OUTER JOIN other_filing o
          ON f.cusip = o.cusip
          AND coalesce(f.option_type, '') = coalesce(o.option_type, '')
      ORDER BY f.value DESC NULLS LAST, o.value DESC NULLS LAST
    SQL

    rows = AggregateHolding.find_by_sql([query, id: filing.id, other_id: other_filing.id]).map do |r|
      shares_diff = r.shares_or_principal_amount.to_i - r.other_shares_or_principal_amount.to_i
      value_diff = r.value.to_i - r.other_value.to_i

      if r.other_shares_or_principal_amount.to_i > 0
        shares_pct = 100 * (r.shares_or_principal_amount.to_f / r.other_shares_or_principal_amount.to_f - 1)
      end

      if r.other_value.to_i > 0
        value_pct = 100 * (r.value.to_f / r.other_value.to_f - 1)
      end

      [
        r.issuer_name,
        r.class_title.upcase,
        r.cusip,
        r.option_type,
        r.shares_or_principal_amount.to_i,
        r.other_shares_or_principal_amount.to_i,
        shares_diff,
        shares_pct&.round(1),
        r.value.to_i,
        r.other_value.to_i,
        value_diff,
        value_pct&.round(1)
      ]
    end

    {data: rows}
  end

  def self.all_cusip_holdings_to_datatable(cusip:, year:, quarter:)
    holdings_scope = AggregateHolding.all_cusip_holdings(cusip, year, quarter)

    median_per_share = holdings_scope.
      map { |h| h.value_per_share if h.option_type.blank? }.
      compact.
      median

    total_value = 0

    rows = holdings_scope.map do |h|
      report_value = h.value
      report_value /= 1000 if value_likely_overstated_by_1000?(h, median_per_share)

      total_value += report_value if report_value && h.option_type.blank?

      f = h.thirteen_f_with_minimal_fields

      [
        [f.name, f.filer.to_param],
        [f.report_date, f.to_param],
        report_value&.to_i,
        h.shares_or_principal_amount&.to_i,
        h.option_type
      ]
    end

    {data: rows, total_value: total_value.to_i}
  end

  def self.manager_cusip_history_to_datatable(cusip:, manager_cik:)
    rows = AggregateHolding.manager_cusip_holdings(cusip, manager_cik).map do |h|
      if h.value && h.amendment_type != "new holdings"
        pct_of_total = 100 * h.value.to_f / h.holdings_value_calculated.to_f
      end

      year = h.report_date.year
      quarter = (h.report_date.month - 1) / 3 + 1
      filing_param = ThirteenF.to_param(h.external_id, h.name, h.report_quarter, h.report_year, h.amendment_type)

      [
        [h.report_date, filing_param],
        h.value&.to_i,
        pct_of_total&.round(1),
        h.shares_or_principal_amount&.to_i,
        h.option_type,
        h.date_filed,
        [year, quarter]
      ]
    end

    {data: rows}
  end

  private

  def self.value_likely_overstated_by_1000?(holding, median_per_share)
    return unless median_per_share && holding.value_per_share && holding.option_type.blank?
    (holding.value_per_share / median_per_share).between?(800, 1200)
  end
end
