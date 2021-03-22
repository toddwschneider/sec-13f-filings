class CreateThirteenFFilers < ActiveRecord::Migration[6.1]
  def up
    create_view :thirteen_f_filers, materialized: true
    add_index :thirteen_f_filers, :cik, unique: true
    add_index :thirteen_f_filers, :name, using: :gin, opclass: {title: :gin_trgm_ops}
  end

  def down
    drop_view :thirteen_f_filers, materialized: true
  end
end
