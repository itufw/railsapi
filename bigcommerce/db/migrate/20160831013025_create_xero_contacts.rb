class CreateXeroContacts < ActiveRecord::Migration
  def change
    create_table :xero_contacts, :id => false do |t|
      t.string :xero_contact_id, limit: 36, null: false, index: true, primary: true
      t.string :name, :firstname, :lastname, :email, :skype_username
      t.string :bank_account_details, :status, :is_customer, :is_supplier, index: true
      t.datetime :date_modified


      t.timestamps null: false
    end
    execute "ALTER TABLE xero_contacts ADD PRIMARY KEY (xero_contact_id);"
  end
end
