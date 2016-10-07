class CreateXeroContacts < ActiveRecord::Migration
  def change
    create_table :xero_contacts, :id => false do |t|
	  t.string :xero_contact_id, limit: 36, null: false, index: true, primary: true
      t.string :name, :firstname, :lastname, :email, :skype_user_name, :contact_number, :contact_status
      t.datetime :updated_date
      t.string :account_number, :tax_number, :bank_account_details, :accounts_receivable_tax_type
      t.string :accounts_payable_tax_type, :contact_groups, :default_currency
      t.string :purchases_default_account_code, :sales_default_account_code
      t.boolean :is_supplier, :is_customer

      t.timestamps null: false
    end
    execute "ALTER TABLE xero_contacts ADD PRIMARY KEY (xero_contact_id);"
  end
end
