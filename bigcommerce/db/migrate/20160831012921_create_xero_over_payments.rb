class CreateXeroOverPayments < ActiveRecord::Migration
  def change
    create_table :xero_over_payments, :id => false do |t|
      t.string :xero_over_payment_id, limit: 36, primary: true, null: false, index: true
      t.string :xero_contact_id, limit: 36, null: false, index: true
      t.string :xero_contact_name, :status, :line_amount_type, :type
      t.decimal :sub_total, :total, :total_tax, precision: 8, scale: 2


      t.timestamps null: false
    end
    execute "ALTER TABLE xero_over_payments ADD PRIMARY KEY (xero_over_payment_id);"
  end
end
