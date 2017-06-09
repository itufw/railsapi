class ContactMergeSalesforce < ActiveRecord::Migration
  def change
    add_column :contacts, :salesforce_contact_id, :string
    add_column :contacts, :personal_number, :string
    add_column :contacts, :preferred_contact_number, :text
    add_column :contacts, :time_unavailable, :text
  end
end
