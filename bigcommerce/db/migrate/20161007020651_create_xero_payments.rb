class CreateXeroPayments < ActiveRecord::Migration
  def change
    create_table :xero_payments, :id => false do |t|
      t.string :xero_payment_id, limit: 36, primary: true, null: false, index: true
      t.string :xero_invoice_id, limit: 36, index: true
      t.string :invoice_number, :invoice_type, index: true
      t.string :xero_contact_id, limit: 36, index: true
      t.string :contact_name
      t.string :xero_account_id, limit: 36, index: true
      t.decimal :bank_amount, :amount, :currency_rate, scale: 2, precision: 8
      t.datetime :date, :updated_date
      t.string :payment_type, :status, :reference
      t.boolean :is_reconciled

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_payments ADD PRIMARY KEY (xero_payment_id);"
  end
end
