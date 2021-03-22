class CreateHoldings < ActiveRecord::Migration[6.1]
  def change
    create_table :holdings do |t|
      t.bigint :thirteen_f_id, null: false
      t.text :cusip, null: false
      t.text :issuer_name
      t.text :class_title
      t.numeric :value
      t.numeric :shares_or_principal_amount
      t.text :shares_or_principal_amount_type
      t.text :option_type
      t.text :investment_discretion
      t.text :other_manager
      t.bigint :voting_authority_sole
      t.bigint :voting_authority_shared
      t.bigint :voting_authority_none
      t.timestamps
    end

    add_index :holdings, :thirteen_f_id
    add_index :holdings, %i(cusip thirteen_f_id)

    create_table :aggregate_holdings do |t|
      t.bigint :thirteen_f_id, null: false
      t.text :cusip, null: false
      t.text :issuer_name
      t.text :class_title
      t.numeric :value
      t.numeric :shares_or_principal_amount
      t.text :shares_or_principal_amount_type
      t.text :option_type
      t.bigint :voting_authority_sole
      t.bigint :voting_authority_shared
      t.bigint :voting_authority_none
      t.timestamps
    end

    add_index :aggregate_holdings, :thirteen_f_id
    add_index :aggregate_holdings, %i(cusip thirteen_f_id)
  end
end
