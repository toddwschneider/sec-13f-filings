class CompanyCusipLookup < ApplicationRecord
  def readonly?
    true
  end

  scope :autocomplete, -> (query, min_holdings_count: 10) {
    where("issuer_name ILIKE ? OR symbol ILIKE ? OR cusip = ?", "%#{query}%", "#{query}%", query.upcase).
      where("holdings_count >= ?", min_holdings_count).
      order([Arel.sql("symbol = ? DESC NULLS LAST, holdings_count DESC, lower(issuer_name)"), query.upcase])
  }

  def self.refresh!
    Scenic.database.refresh_materialized_view(
      :company_cusip_lookups,
      concurrently: true
    )
  end

  def symbol_and_name
    "#{symbol} #{issuer_name}".strip
  end

  def investment_type
    case shares_or_principal_amount_type
    when "sh"
      "Equity"
    when "prn"
      "Debt"
    end
  end

  def shares_or_principal_header
    case shares_or_principal_amount_type
    when "sh"
      "Shares"
    when "prn"
      "Principal"
    end
  end
end
