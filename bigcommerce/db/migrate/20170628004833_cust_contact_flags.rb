class CustContactFlags < ActiveRecord::Migration
  def change
    remove_column :cust_contacts, :c_receive_invoice
    remove_column :cust_contacts, :receive_sales
    remove_column :cust_contacts, :key_account

    add_column :cust_contacts, :receive_invoice, :integer
    add_column :cust_contacts, :receive_portfolio, :integer
    add_column :cust_contacts, :key_accountant, :integer
  end
end
