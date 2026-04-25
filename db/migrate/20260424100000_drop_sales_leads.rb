class DropSalesLeads < ActiveRecord::Migration[8.1]
  def up
    drop_table :sales_leads, if_exists: true
  end

  def down
    create_table :sales_leads do |t|
      t.string :facility_name, null: false
      t.string :segment
      t.string :area
      t.string :phone
      t.string :region, null: false
      t.string :priority
      t.string :it_literacy
      t.string :sales_status, null: false, default: "未着手"
      t.string :person_in_charge
      t.date :contacted_at
      t.date :appointment_date
      t.date :visited_at
      t.integer :proposal_amount
      t.string :subsidy_status
      t.date :closed_at
      t.date :monthly_start_date
      t.text :memo
      t.string :source
      t.string :source_url
      t.boolean :duplicate_flag, default: false, null: false
      t.timestamps
    end

    add_index :sales_leads, :region
    add_index :sales_leads, :sales_status
    add_index :sales_leads, %i[facility_name phone region], unique: true, name: "index_sales_leads_on_unique_key"
  end
end
