class CreateXeroCreditNotes < ActiveRecord::Migration
  def change
    create_table :xero_credit_notes, :id => false do |t|
      t.string :xero_credit_note_id, limit: 36, primary: true, null: false, index: true
      t.string :credit_note_number, index: true
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :xero_contact_name, :status, :line_amount_type, :type, index: true
      t.decimal :sub_total, :total, :total_tax, :remaining_credit, precision: 8, scale: 2
      t.datetime :date, :date_modified, :fully_paid_on_date

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_credit_notes ADD PRIMARY KEY (xero_credit_note_id);"
  end
end
