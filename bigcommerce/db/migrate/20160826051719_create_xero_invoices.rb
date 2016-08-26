class CreateXeroInvoices < ActiveRecord::Migration
  def change
    create_table :xero_invoices, :id => false  do |t|
      t.string :invoice_id, limit: 36, primary: true, null: false
      t.string :order_id, index: true
      t.string :contact_id, limit: 36, index: true
      t.string :contact_name
      t.decimal :total, :sub_total, :total_tax, :amount_due, :amount_paid, :amount_credited, scale: 2, precision: 8
      t.datetime :date, :due_date, :updated_date
      t.string :status, :type, :has_attachments

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_invoices ADD PRIMARY KEY (invoice_id);"
  end
end
