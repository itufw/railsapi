class CreateXeroInvoiceLineItems < ActiveRecord::Migration
  def change
    create_table :xero_invoice_line_items, :id => false do |t|
      t.string :xero_invoice_line_item_id, limit: 36, primary: true, null: false, index: true
      t.string :xero_invoice_id, limit: 36, null: false, index: true
      t.string :item_code, :description
      t.decimal :unit_amount, :line_amount, :tax_amount, scale: 2, precision: 8
      t.integer :qty
      t.string :tax_type, :account_code

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_invoice_line_items ADD PRIMARY KEY (xero_invoice_line_item_id);"
  end
end
