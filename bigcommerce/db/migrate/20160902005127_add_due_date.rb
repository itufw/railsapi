class AddDueDate < ActiveRecord::Migration
  def change
  	add_column :xero_invoices, :due_date, :datetime
  end
end
