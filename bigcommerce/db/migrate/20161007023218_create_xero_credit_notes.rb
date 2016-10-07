class CreateXeroCreditNotes < ActiveRecord::Migration
  def change
    create_table :xero_credit_notes, :id => false do |t|
      t.string :xero_credit_note_id, limit: 36, primary: true, null: false, index: true
      t.string :credit_note_number, index: true
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :contact_name, :status, :line_amount_type, :type, index: true
      t.decimal :sub_total, :total, :total_tax, :remaining_credit, precision: 8, scale: 2
      t.datetime :date, :updated_date, :fully_paid_on_date
      t.string :currency_code
      t.decimal :currency_rate, precision: 8, scale: 2
      t.string :reference
      t.boolean :sent_to_contact

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_credit_notes ADD PRIMARY KEY (xero_credit_note_id);"
  end
end
