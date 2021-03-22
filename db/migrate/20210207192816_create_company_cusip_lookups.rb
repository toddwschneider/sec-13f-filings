class CreateCompanyCusipLookups < ActiveRecord::Migration[6.1]
  def up
    create_view :company_cusip_lookups, materialized: true
    add_index :company_cusip_lookups, :cusip, unique: true
    add_index :company_cusip_lookups, :issuer_name, using: :gin, opclass: {title: :gin_trgm_ops}
  end

  def down
    drop_view :company_cusip_lookups, materialized: true
  end
end
