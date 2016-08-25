class UniqueXeroInvoices < ActiveRecord::Migration
  def change
  	add_index :xero_invoices, :invoice_id, unique: true
  end
end
