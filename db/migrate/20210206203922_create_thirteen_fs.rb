class CreateThirteenFs < ActiveRecord::Migration[6.1]
  def change
    enable_extension :pg_trgm

    create_table :thirteen_fs do |t|
      t.text :external_id, null: false
      t.text :cik, null: false
      t.text :name, null: false
      t.text :form_type, null: false
      t.text :directory_url, null: false
      t.date :date_filed, null: false
      t.date :report_date
      t.text :street1
      t.text :street2
      t.text :city
      t.text :state_or_country
      t.text :zip_code
      t.integer :other_included_managers_count
      t.integer :holdings_count_reported
      t.integer :holdings_count_calculated
      t.numeric :holdings_value_reported
      t.numeric :holdings_value_calculated
      t.boolean :confidential_omitted
      t.integer :filing_year, null: false
      t.integer :filing_quarter, null: false
      t.integer :report_year
      t.integer :report_quarter
      t.jsonb :other_managers, null: false, default: []
      t.text :primary_doc_url
      t.text :info_table_url
      t.text :primary_doc_xml
      t.text :info_table_xml
      t.timestamp :xml_data_fetched_at
      t.timestamps
    end

    add_index :thirteen_fs, :external_id, unique: true
    add_index :thirteen_fs, %i(cik report_date)
    add_index :thirteen_fs, :report_date
    add_index :thirteen_fs, :date_filed
    add_index :thirteen_fs, :name, using: :gin, opclass: {title: :gin_trgm_ops}
  end
end
