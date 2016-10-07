class AddXeroContacttoCustomer < ActiveRecord::Migration
  def change
  	add_column :customers, :xero_contact_id, :string, limit: 36, index: true
  end
end
