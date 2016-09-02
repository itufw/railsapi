class CreateXeroOverPaymentAllocations < ActiveRecord::Migration
  def change
    create_table :xero_over_payment_allocations, :id => false do |t|
      t.string :xero_over_payment_allocation_id, limit: 36, null: false, primary: true
      t.string :xero_over_payment_id, limit: 36, null: false, index: true
      t.string :xero_invoice_id, limit: 36, null: false, index: true
      t.integer :xero_invoice_number, limit: 8, unsigned: true, index: true
      t.decimal :applied_amount, precision: 8, scale: 2
      t.datetime :date

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_over_payment_allocations ADD PRIMARY KEY (xero_over_payment_allocation_id);"
  end
end
