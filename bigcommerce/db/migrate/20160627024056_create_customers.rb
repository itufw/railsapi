class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|

	  t.text :firstname, :lastname, :company, :email, :phone, limit: 255

	  t.text :actual_name

	  t.integer :staff_id, :cust_type_id, :cust_group_id, :cust_store_id, index: true

	  t.datetime :date_created
	  t.datetime :date_modified

	  t.decimal :store_credit, scale: 2, precision: 6

	  t.text :registration_ip_address, limit: 32
	  t.text :notes      

    t.timestamps null: false
    end
  end
end
