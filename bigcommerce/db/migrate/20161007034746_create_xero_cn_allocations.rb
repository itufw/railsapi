class CreateXeroCnAllocations < ActiveRecord::Migration
  def change
    create_table :xero_cn_allocations, :id => false do |t|

      t.string :xero_cn_allocation_id, limit: 36, index: true, null: false, primary: true

      t.string :xero_credit_note_id, limit: 36, index: true

      t.decimal :applied_amount, precision: 8, scale: 2
      t.datetime :date
      t.string :xero_invoice_id, limit: 36, null: false, index: true
      t.string :invoice_number, index: true
      t.timestamps null: false
    end
    execute "ALTER TABLE xero_cn_allocations ADD PRIMARY KEY (xero_cn_allocation_id);"
  end
end