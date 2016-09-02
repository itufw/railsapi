class CreateXeroReceipts < ActiveRecord::Migration
  def change
    create_table :xero_receipts, :id => false do |t|
      t.string :xero_receipt_id, limit: 36, primary: true, null: false, index: true
      t.string :receipt_number, :status
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :xero_contact_name
      t.datetime :date, :date_modified
      t.decimal :sub_total, :total, :total_tax, precision: 8, scale: 2



      t.timestamps null: false
    end
    execute "ALTER TABLE xero_receipts ADD PRIMARY KEY (xero_receipt_id);"
  end
end
