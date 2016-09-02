class CreateXeroInvoices < ActiveRecord::Migration
  def change
    create_table :xero_invoices, :id => false do |t|
      t.string :xero_invoice_id, limit: 36, primary: true, null: false, index: true
      t.integer :xero_invoice_number, limit: 8, unsigned: true, index: true
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :xero_contact_name
      t.decimal :sub_total, :total, :total_tax, :amount_due, :amount_paid, :amount_credited, precision: 8, scale: 2
      t.datetime :date, :date_modified
      t.string :status, :line_amount_types, :type, index: true



      t.timestamps null: false
    end
    execute "ALTER TABLE xero_invoices ADD PRIMARY KEY (xero_invoice_id);"
  end
end
