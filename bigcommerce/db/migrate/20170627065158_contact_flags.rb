class ContactFlags < ActiveRecord::Migration
  def change
    add_column :cust_contacts, :receive_statement, :integer
    add_column :cust_contacts, :receive_sales, :integer

    add_column :cust_contacts, :key_sales, :integer
    add_column :cust_contacts, :key_account, :integer
  end
end
