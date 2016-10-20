class RenameTaxCode < ActiveRecord::Migration
  def change
  	#rename_table :tax_codes, :xero_account_codes

  	remove_column :xero_account_codes, :tax_code
  	add_column :xero_account_codes, :account_code, :string, index: true

  	remove_column :xero_account_codes, :customer_type
  	add_column :xero_account_codes, :account_name, :string, index: true

  	add_column :xero_account_codes, :tax_type, :string, index: true
  end
end
