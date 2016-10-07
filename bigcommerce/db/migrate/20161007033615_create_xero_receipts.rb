class CreateXeroReceipts < ActiveRecord::Migration
  def change
    create_table :xero_receipts, :id => false do |t|
      t.string :xero_receipt_id, limit: 36, primary: true, null: false, index: true
      t.string :xero_contact_id, limit: 36, index: true
      t.string :contact_name
      t.string :xero_user_id, limit: 36, index: true
      t.string :user_firstname, :user_lastname
      t.string :receipt_number, :status
      t.decimal :sub_total, :total_tax, :total, precision: 8, scale: 2
      t.datetime :date, :updated_date
      t.string :url, :reference, :line_amount_types

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_receipts ADD PRIMARY KEY (xero_receipt_id);"
  end
end
