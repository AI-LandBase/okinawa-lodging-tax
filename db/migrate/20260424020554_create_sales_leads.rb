class CreateSalesLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :sales_leads do |t|
      # 基本情報
      t.string :facility_name, null: false, comment: "施設名"
      t.string :segment, comment: "セグメント（大型ホテル・リゾート等）"
      t.string :area, comment: "市町村"
      t.string :phone, comment: "電話番号"
      t.string :region, null: false, comment: "地域区分（北部 / 中部 / 南部）"

      # 営業管理
      t.string :priority, comment: "優先度"
      t.string :it_literacy, comment: "IT化度推定"
      t.string :sales_status, null: false, default: "未着手", comment: "営業ステータス"
      t.string :person_in_charge, comment: "担当者"
      t.date :contacted_at, comment: "初回接触日"
      t.date :appointment_date, comment: "アポ日"
      t.date :visited_at, comment: "訪問日"
      t.integer :proposal_amount, comment: "提案金額（円・税抜）"
      t.string :subsidy_status, comment: "補助金申請状況"
      t.date :closed_at, comment: "成約日"
      t.date :monthly_start_date, comment: "月額開始日"
      t.text :memo, comment: "メモ"

      # データソース情報
      t.string :source, comment: "ソース分類"
      t.string :source_url, comment: "ソースURL"
      t.boolean :duplicate_flag, default: false, null: false, comment: "重複候補フラグ"

      t.timestamps
    end

    add_index :sales_leads, :region
    add_index :sales_leads, :sales_status
    add_index :sales_leads, %i[facility_name phone region], unique: true, name: "index_sales_leads_on_unique_key"
  end
end
