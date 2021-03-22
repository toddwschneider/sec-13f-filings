# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_03_13_203021) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "aggregate_holdings", force: :cascade do |t|
    t.bigint "thirteen_f_id", null: false
    t.text "cusip", null: false
    t.text "issuer_name"
    t.text "class_title"
    t.decimal "value"
    t.decimal "shares_or_principal_amount"
    t.text "shares_or_principal_amount_type"
    t.text "option_type"
    t.bigint "voting_authority_sole"
    t.bigint "voting_authority_shared"
    t.bigint "voting_authority_none"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cusip", "thirteen_f_id"], name: "index_aggregate_holdings_on_cusip_and_thirteen_f_id"
    t.index ["thirteen_f_id"], name: "index_aggregate_holdings_on_thirteen_f_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "holdings", force: :cascade do |t|
    t.bigint "thirteen_f_id", null: false
    t.text "cusip", null: false
    t.text "issuer_name"
    t.text "class_title"
    t.decimal "value"
    t.decimal "shares_or_principal_amount"
    t.text "shares_or_principal_amount_type"
    t.text "option_type"
    t.text "investment_discretion"
    t.text "other_manager"
    t.bigint "voting_authority_sole"
    t.bigint "voting_authority_shared"
    t.bigint "voting_authority_none"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["cusip", "thirteen_f_id"], name: "index_holdings_on_cusip_and_thirteen_f_id"
    t.index ["thirteen_f_id"], name: "index_holdings_on_thirteen_f_id"
  end

  create_table "thirteen_fs", force: :cascade do |t|
    t.text "external_id", null: false
    t.text "cik", null: false
    t.text "name", null: false
    t.text "form_type", null: false
    t.text "directory_url", null: false
    t.date "date_filed", null: false
    t.date "report_date"
    t.text "street1"
    t.text "street2"
    t.text "city"
    t.text "state_or_country"
    t.text "zip_code"
    t.integer "other_included_managers_count"
    t.integer "holdings_count_reported"
    t.integer "holdings_count_calculated"
    t.decimal "holdings_value_reported"
    t.decimal "holdings_value_calculated"
    t.boolean "confidential_omitted"
    t.integer "filing_year", null: false
    t.integer "filing_quarter", null: false
    t.integer "report_year"
    t.integer "report_quarter"
    t.jsonb "other_managers", default: [], null: false
    t.text "primary_doc_url"
    t.text "info_table_url"
    t.text "primary_doc_xml"
    t.text "info_table_xml"
    t.datetime "xml_data_fetched_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "report_type"
    t.text "amendment_type"
    t.integer "amendment_number"
    t.text "file_number"
    t.bigint "restated_by_id"
    t.integer "aggregate_holdings_count"
    t.index ["amendment_type"], name: "index_thirteen_fs_on_amendment_type"
    t.index ["cik", "report_date"], name: "index_thirteen_fs_on_cik_and_report_date"
    t.index ["date_filed"], name: "index_thirteen_fs_on_date_filed"
    t.index ["external_id"], name: "index_thirteen_fs_on_external_id", unique: true
    t.index ["name"], name: "index_thirteen_fs_on_name", opclass: :gin_trgm_ops, using: :gin
    t.index ["report_date"], name: "index_thirteen_fs_on_report_date"
    t.index ["report_year", "report_quarter", "restated_by_id"], name: "index_thirteen_fs_on_year_quarter_restated"
    t.index ["restated_by_id"], name: "index_thirteen_fs_on_restated_by_id"
  end


  create_view "company_cusip_lookups", materialized: true, sql_definition: <<-SQL
      WITH holding_counts AS (
           SELECT aggregate_holdings.cusip,
              aggregate_holdings.issuer_name,
              aggregate_holdings.class_title,
              aggregate_holdings.shares_or_principal_amount_type,
              count(*) AS holdings_count
             FROM aggregate_holdings
            GROUP BY aggregate_holdings.cusip, aggregate_holdings.issuer_name, aggregate_holdings.class_title, aggregate_holdings.shares_or_principal_amount_type
          )
   SELECT DISTINCT ON (holding_counts.cusip) holding_counts.cusip,
      holding_counts.issuer_name,
      holding_counts.class_title,
      holding_counts.shares_or_principal_amount_type,
      holding_counts.holdings_count
     FROM holding_counts
    ORDER BY holding_counts.cusip, holding_counts.holdings_count DESC, holding_counts.issuer_name, holding_counts.class_title;
  SQL
  add_index "company_cusip_lookups", ["cusip"], name: "index_company_cusip_lookups_on_cusip", unique: true
  add_index "company_cusip_lookups", ["issuer_name"], name: "index_company_cusip_lookups_on_issuer_name", opclass: :gin_trgm_ops, using: :gin

  create_view "thirteen_f_filers", materialized: true, sql_definition: <<-SQL
      WITH most_recent AS (
           SELECT DISTINCT ON (thirteen_fs.cik) thirteen_fs.cik,
              thirteen_fs.name,
              thirteen_fs.city,
              thirteen_fs.state_or_country,
              thirteen_fs.date_filed AS most_recent_date_filed
             FROM thirteen_fs
            ORDER BY thirteen_fs.cik, thirteen_fs.date_filed DESC, thirteen_fs.id
          ), counts AS (
           SELECT thirteen_fs.cik,
              count(*) AS filings_count
             FROM thirteen_fs
            GROUP BY thirteen_fs.cik
          )
   SELECT most_recent.cik,
      most_recent.name,
      most_recent.city,
      most_recent.state_or_country,
      most_recent.most_recent_date_filed,
      counts.filings_count
     FROM (most_recent
       JOIN counts ON ((most_recent.cik = counts.cik)));
  SQL
  add_index "thirteen_f_filers", ["cik"], name: "index_thirteen_f_filers_on_cik", unique: true
  add_index "thirteen_f_filers", ["name"], name: "index_thirteen_f_filers_on_name", opclass: :gin_trgm_ops, using: :gin

  create_view "cusip_quarterly_filings_counts", materialized: true, sql_definition: <<-SQL
      SELECT h.cusip,
      f.report_year,
      f.report_quarter,
      count(*) AS filings_count
     FROM (thirteen_fs f
       JOIN aggregate_holdings h ON ((h.thirteen_f_id = f.id)))
    GROUP BY h.cusip, f.report_year, f.report_quarter
    ORDER BY h.cusip, f.report_year, f.report_quarter;
  SQL
  add_index "cusip_quarterly_filings_counts", ["cusip", "report_year", "report_quarter"], name: "index_cusip_quarterly_filings_unique", unique: true

end
