class CreateXeroContacts < ActiveRecord::Migration
  def change
    create_table :xero_contacts, :id => false do |t|
      t.string :contact_id, limit: 36, primary: true, null: false
      t.string :contact_status, :contact_name
      t.datetime :updated_date
      t.integer :is_supplier, :is_customer, limit: 1

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_contacts ADD PRIMARY KEY (contact_id);"
  end
end
