class Holding < ApplicationRecord
  belongs_to :thirteen_f

  scope :descend_by_value, -> { order("value DESC, lower(issuer_name), id") }

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
