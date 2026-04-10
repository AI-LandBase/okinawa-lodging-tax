class CreateStays < ActiveRecord::Migration[8.1]
  def up
    create_table :stays, id: :uuid do |t|
      t.date    :check_in_date,           null: false, comment: "チェックイン日"
      t.integer :nights,                  null: false, comment: "連泊数"
      t.string  :guest_name,              null: false, comment: "代表者氏名"
      t.integer :num_guests,              null: false, comment: "総宿泊人数"
      t.integer :num_taxable_guests,      null: false, comment: "課税対象人数"
      t.integer :num_exempt_guests,       null: false, default: 0, comment: "免除人数"
      t.integer :nightly_rate,            null: false, comment: "1人1泊宿泊料金（税抜）"
      t.integer :taxable_amount,          null: false, comment: "課税対象合計（計算結果）"
      t.integer :tax_amount,              null: false, comment: "宿泊税額（計算結果）"
      t.string  :tax_rule_version,        null: false, default: "okinawa-2027-02-01", comment: "税計算に使用した条例 version"
      t.string  :exemption_reason,        comment: "免除理由"
      t.string  :channel,                 comment: "予約チャネル名（Airbnb / Booking 等）"
      t.string  :external_reservation_id, comment: "チャネル側の予約ID（突合用）"
      t.string  :payment_method,          comment: "決済手段（square / cash / ota / other）"
      t.text    :memo,                    comment: "自由メモ"
      t.string  :status,                  null: false, default: "active", comment: "ステータス（active / cancelled）"

      t.references :created_by_user, null: false, foreign_key: { to_table: :users }, comment: "作成したスタッフ"
      t.references :updated_by_user, null: false, foreign_key: { to_table: :users }, comment: "最終更新したスタッフ"

      t.timestamps null: false
    end

    add_index :stays, :check_in_date
    add_index :stays, :status
  end

  def down
    drop_table :stays
  end
end
