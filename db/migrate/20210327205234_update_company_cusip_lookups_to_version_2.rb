class UpdateCompanyCusipLookupsToVersion2 < ActiveRecord::Migration[6.1]
  def up
    update_view :company_cusip_lookups, version: 2, materialized: true

    add_index :company_cusip_lookups, :symbol

    add_index :company_cusip_lookups,
      :symbol,
      using: :gin,
      opclass: {title: :gin_trgm_ops},
      name: "index_company_cusip_lookups_on_symbol_trigram"

    add_index :company_cusip_lookups,
      "holdings_count, lower(issuer_name)",
      name: "index_company_cusip_lookups_on_count_and_name"

    add_index :thirteen_f_filers, "lower(name)"
  end

  def down
    remove_index :thirteen_f_filers, name: "index_thirteen_f_filers_on_lower_name"

    remove_index :company_cusip_lookups, name: "index_company_cusip_lookups_on_symbol"
    remove_index :company_cusip_lookups, name: "index_company_cusip_lookups_on_symbol_trigram"
    remove_index :company_cusip_lookups, name: "index_company_cusip_lookups_on_count_and_name"
    update_view :company_cusip_lookups, version: 1, materialized: true
  end
end
