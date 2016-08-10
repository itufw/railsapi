class AddCustomerColumns < ActiveRecord::Migration
  def change
  	add_column :customers, :cust_style_id, :integer
  	add_column :customers, :region, :string
  end
end
