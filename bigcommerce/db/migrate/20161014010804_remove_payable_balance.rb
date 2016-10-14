class RemovePayableBalance < ActiveRecord::Migration
  def change
  	remove_column :xero_contacts, :accounts_payable_outstanding
  	remove_column :xero_contacts, :accounts_payable_overdue
  	add_column :xero_invoice_line_items, :invoice_number, :string, index: true
  end
end
