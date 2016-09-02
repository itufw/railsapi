class CreateXeroCreditNoteAllocations < ActiveRecord::Migration
  def change
    create_table :xero_credit_note_allocations, :id => false do |t|
      t.string :xero_credit_note_allocation_id, limit: 36, null: false, primary: true

      t.string :xero_credit_note_id, limit: 36, null: false, index: true
      t.string :xero_invoice_id, limit: 36, null: false, index: true
      t.integer :invoice_number, limit: 8, unsigned: true, index: true

      t.datetime :date
      t.decimal :applied_amount, precision: 8, scale: 2

      t.timestamps null: false
    end
  end
end
