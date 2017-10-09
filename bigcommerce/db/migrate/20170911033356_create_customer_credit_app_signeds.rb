class CreateCustomerCreditAppSigneds < ActiveRecord::Migration
  def change
    create_table :customer_credit_app_signeds do |t|
      t.integer :customer_credit_app_id, :contact_id, :customer_id, :assigned_staff, :active
      t.datetime :end_date
      t.text :end_note
      t.timestamps null: false
    end
  end
end
