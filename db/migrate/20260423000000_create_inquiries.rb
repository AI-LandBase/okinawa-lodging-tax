class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.string :facility_name, null: false, comment: "施設名"
      t.string :contact_name, null: false, comment: "担当者名"
      t.string :email, null: false, comment: "メールアドレス"
      t.string :phone, comment: "電話番号"
      t.string :facility_type, comment: "施設の種類（minpaku / simple_lodging / ryokan / hotel / other）"
      t.string :has_pc, comment: "PC保有状況（mac / windows / other_pc / no）"
      t.text :message, comment: "ご相談内容"
      t.timestamps
    end
  end
end
