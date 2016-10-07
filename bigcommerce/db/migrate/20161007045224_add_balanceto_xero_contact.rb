class AddBalancetoXeroContact < ActiveRecord::Migration
  def change
  	add_column :xero_contacts, :accounts_receivable_outstanding, :decimal, precision: 8, scale: 2
  	add_column :xero_contacts, :accounts_receivable_overdue, :decimal, precision: 8, scale: 2

  	add_column :xero_contacts, :accounts_payable_outstanding, :decimal, precision: 8, scale: 2
  	add_column :xero_contacts, :accounts_payable_overdue, :decimal, precision: 8, scale: 2

  end
end
