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

ActiveRecord::Schema[8.1].define(version: 2026_04_24_020554) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "sales_leads", force: :cascade do |t|
    t.date "appointment_date", comment: "アポ日"
    t.string "area", comment: "市町村"
    t.date "closed_at", comment: "成約日"
    t.date "contacted_at", comment: "初回接触日"
    t.datetime "created_at", null: false
    t.boolean "duplicate_flag", default: false, null: false, comment: "重複候補フラグ"
    t.string "facility_name", null: false, comment: "施設名"
    t.string "it_literacy", comment: "IT化度推定"
    t.text "memo", comment: "メモ"
    t.date "monthly_start_date", comment: "月額開始日"
    t.string "person_in_charge", comment: "担当者"
    t.string "phone", comment: "電話番号"
    t.string "priority", comment: "優先度"
    t.integer "proposal_amount", comment: "提案金額（円・税抜）"
    t.string "region", null: false, comment: "地域区分（北部 / 中部 / 南部）"
    t.string "sales_status", default: "未着手", null: false, comment: "営業ステータス"
    t.string "segment", comment: "セグメント（大型ホテル・リゾート等）"
    t.string "source", comment: "ソース分類"
    t.string "source_url", comment: "ソースURL"
    t.string "subsidy_status", comment: "補助金申請状況"
    t.datetime "updated_at", null: false
    t.date "visited_at", comment: "訪問日"
    t.index ["facility_name", "phone", "region"], name: "index_sales_leads_on_unique_key", unique: true
    t.index ["region"], name: "index_sales_leads_on_region"
    t.index ["sales_status"], name: "index_sales_leads_on_sales_status"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end
end
