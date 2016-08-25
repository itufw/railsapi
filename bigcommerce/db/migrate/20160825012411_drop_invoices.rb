class DropInvoices < ActiveRecord::Migration
  def change
  	drop_table :invoices
  end
end
