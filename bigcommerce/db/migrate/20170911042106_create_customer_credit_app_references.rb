class CreateCustomerCreditAppReferences < ActiveRecord::Migration
  def change
    create_table :customer_credit_app_references do |t|
      t.integer :customer_credit_app_id, :customer_id
      t.text :company_name, :contact_name
      t.text :check1, :check2, :check3, :check4
      t.text :notes
      t.integer :checked_by
      t.timestamps null: false
    end
  end
end
