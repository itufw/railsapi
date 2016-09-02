class RemoveDate < ActiveRecord::Migration
  def change
  	remove_column :xero_credit_note_allocations, :date
  end
end
