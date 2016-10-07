class CreateXeroOverpayments < ActiveRecord::Migration
  def change
    create_table :xero_overpayments, :id => false do |t|
      t.string :xero_overpayment_id, limit: 36, primary: true, null: false, index: true

      t.string :xero_invoice_id, limit: 36, null: false, index: true
      t.string :invoice_number, index: true

      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :contact_name


      t.decimal :sub_total, :total_tax, :total, :remaining_credit
      t.datetime :date, :updated_date
      t.string :type, :status, :line_amount_types, :currency_code
      t.boolean :has_attachments


      t.timestamps null: false
    end
    execute "ALTER TABLE xero_overpayments ADD PRIMARY KEY (xero_overpayment_id);"
  end
end
