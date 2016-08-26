class CreateXeroCreditNotes < ActiveRecord::Migration
  def change
    create_table :xero_credit_notes, :id => false do |t|
      t.string :credit_note_id, primary: true, null: false, index: true, limit: 36
      t.string :invoice_id, :contact_id, limit: 36, index: true
      t.string :contact_name, :credit_note_number, :order_id, :status, :type
      t.datetime :date, :updated_date, :fully_paid_on_date, :date_applied
      t.decimal :remaning_credit, :sub_total, :total, :total_tax, :applied_amount, precision: 8, scale: 2

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_credit_notes ADD PRIMARY KEY (credit_note_id);"
  end
end
