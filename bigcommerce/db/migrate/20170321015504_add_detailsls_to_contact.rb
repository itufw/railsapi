class AddDetailslsToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :name, :string
    add_column :contacts, :number, :string
    add_column :contacts, :area_code, :string
    add_column :contacts, :phone_type, :string
    add_column :contacts, :xero_contact_id, :string, limit: 36
    add_column :contacts, :customer_id, :int, limit: 10

  end
end
