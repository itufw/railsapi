class RemoveLastName < ActiveRecord::Migration
  def change
  	remove_column :xero_contacts, :lastname
  end
end
