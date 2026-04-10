# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: "", comment: "ログインID（メールアドレス）"
      t.string :encrypted_password, null: false, default: "", comment: "パスワードハッシュ（Devise管理）"

      ## Recoverable
      t.string   :reset_password_token,   comment: "パスワードリセット用トークン"
      t.datetime :reset_password_sent_at, comment: "パスワードリセットメール送信日時"

      ## Rememberable
      t.datetime :remember_created_at, comment: "ログイン記憶開始日時"

      ## v0 追加カラム
      t.string  :name,   null: false, default: "", comment: "表示名"
      t.boolean :active,  null: false, default: true, comment: "有効フラグ（false でログイン不可）"

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
