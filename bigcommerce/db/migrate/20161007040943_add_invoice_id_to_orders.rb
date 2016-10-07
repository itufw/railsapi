class AddInvoiceIdToOrders < ActiveRecord::Migration
  def change
  	add_column :orders, :xero_invoice_id, :string, limit: 36, index: true
  	add_column :orders, :xero_invoice_number, :string
  end
end
