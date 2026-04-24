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

  create_table "inquiries", force: :cascade do |t|
    t.string "contact_name", null: false, comment: "担当者名"
    t.datetime "created_at", null: false
    t.string "email", null: false, comment: "メールアドレス"
    t.string "facility_name", null: false, comment: "施設名"
    t.string "facility_type", comment: "施設の種類（minpaku / simple_lodging / ryokan / hotel / other）"
    t.string "has_pc", comment: "PC保有状況（mac / windows / other_pc / no）"
    t.text "message", comment: "ご相談内容"
    t.string "phone", comment: "電話番号"
    t.datetime "updated_at", null: false
  end

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

  create_table "stays", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "channel", comment: "予約チャネル名（Airbnb / Booking 等）"
    t.date "check_in_date", null: false, comment: "チェックイン日"
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id", null: false, comment: "作成したスタッフ"
    t.string "exemption_reason", comment: "免除理由"
    t.string "external_reservation_id", comment: "チャネル側の予約ID（突合用）"
    t.string "guest_name", null: false, comment: "代表者氏名"
    t.text "memo", comment: "自由メモ"
    t.integer "nightly_rate", null: false, comment: "1人1泊宿泊料金（税抜）"
    t.integer "nights", null: false, comment: "連泊数"
    t.integer "num_exempt_guests", default: 0, null: false, comment: "免除人数"
    t.integer "num_guests", null: false, comment: "総宿泊人数"
    t.integer "num_taxable_guests", null: false, comment: "課税対象人数"
    t.string "payment_method", comment: "決済手段（square / cash / ota / other）"
    t.string "status", default: "active", null: false, comment: "ステータス（active / cancelled）"
    t.integer "tax_amount", null: false, comment: "宿泊税額（計算結果）"
    t.string "tax_rule_version", default: "okinawa-2027-02-01", null: false, comment: "税計算に使用した条例 version"
    t.integer "taxable_amount", null: false, comment: "課税対象合計（計算結果）"
    t.datetime "updated_at", null: false
    t.bigint "updated_by_user_id", null: false, comment: "最終更新したスタッフ"
    t.index ["check_in_date"], name: "index_stays_on_check_in_date"
    t.index ["created_by_user_id"], name: "index_stays_on_created_by_user_id"
    t.index ["status"], name: "index_stays_on_status"
    t.index ["updated_by_user_id"], name: "index_stays_on_updated_by_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false, comment: "有効フラグ（false でログイン不可）"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false, comment: "ログインID（メールアドレス）"
    t.string "encrypted_password", default: "", null: false, comment: "パスワードハッシュ（Devise管理）"
    t.string "name", default: "", null: false, comment: "表示名"
    t.datetime "remember_created_at", comment: "ログイン記憶開始日時"
    t.datetime "reset_password_sent_at", comment: "パスワードリセットメール送信日時"
    t.string "reset_password_token", comment: "パスワードリセット用トークン"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.string "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "stays", "users", column: "created_by_user_id"
  add_foreign_key "stays", "users", column: "updated_by_user_id"
end
