class CreateCustomerLeads < ActiveRecord::Migration
  def change
    create_table :customer_leads do |t|
      t.text :firstname, :lastname, :company, :email, :phone, limit: 255
      t.text :actual_name, :region

      t.integer :staff_id, :cust_type_id, :cust_group_id, index: true
      t.integer :cust_style_id
      t.datetime :date_created, :date_modified

      t.timestamps null: false
    end
  end
end
