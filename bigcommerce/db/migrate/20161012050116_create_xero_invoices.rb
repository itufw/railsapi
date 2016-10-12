class CreateXeroInvoices < ActiveRecord::Migration
  def change
    create_table :xero_invoices, :id => false do |t|
      t.string :xero_invoice_id, limit: 36, primary: true, null: false, index: true
      t.string :invoice_number, index: true
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :contact_name
      t.decimal :sub_total, :total_tax, :total, :total_discount, :amount_due, :amount_paid, :amount_credited, precision: 8, scale: 2
      t.datetime :date, :due_date, :fully_paid_on_date, :expected_payment_date, :updated_date, index: true
      t.string :status, :line_amount_types, :invoice_type, :reference, index: true
      t.string :currency_code
      t.decimal :currency_rate, precision: 8, scale: 2
      t.string :url, :reference
      t.string :branding_theme_id, limit: 36
      t.boolean :sent_to_contact, :has_attachments
      t.timestamps null: false
    end
    execute "ALTER TABLE xero_invoices ADD PRIMARY KEY (xero_invoice_id);"
  end
end
