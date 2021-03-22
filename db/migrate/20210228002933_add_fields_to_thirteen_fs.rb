class AddFieldsToThirteenFs < ActiveRecord::Migration[6.1]
  def change
    add_column :thirteen_fs, :report_type, :text
    add_column :thirteen_fs, :amendment_type, :text
    add_column :thirteen_fs, :amendment_number, :integer
    add_column :thirteen_fs, :file_number, :text
    add_column :thirteen_fs, :restated_by_id, :bigint
    add_column :thirteen_fs, :aggregate_holdings_count, :integer

    add_index :thirteen_fs, :amendment_type
    add_index :thirteen_fs, :restated_by_id

    add_index :thirteen_fs,
      %i(report_year report_quarter restated_by_id),
      name: "index_thirteen_fs_on_year_quarter_restated"
  end
end
