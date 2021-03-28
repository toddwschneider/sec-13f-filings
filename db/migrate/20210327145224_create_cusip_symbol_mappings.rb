class CreateCusipSymbolMappings < ActiveRecord::Migration[6.1]
  def change
    create_table :cusip_symbol_mappings do |t|
      t.text :cusip, null: false
      t.text :symbol
      t.text :name
      t.text :exchange
      t.timestamps
    end

    add_index :cusip_symbol_mappings, :cusip, unique: true
  end
end
