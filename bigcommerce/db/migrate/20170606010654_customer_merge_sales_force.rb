class CustomerMergeSalesForce < ActiveRecord::Migration
  def change
    remove_column :customers, :num_days
    remove_column :customers, :end_of_month

    add_column :customers, :salesforce_id, :string
    add_column :customers, :salesforce_owner_id, :string

    add_column :customers, :fax, :string
    add_column :customers, :website, :string
    add_column :customers, :description, :text
    add_column :customers, :note, :string
    add_column :customers, :payment_requirement, :text

    add_column :customers, :email_for_sales, :string
    add_column :customers, :email_for_accounts, :string

    add_column :customers, :street, :string
    add_column :customers, :city, :string
    add_column :customers, :state, :string
    add_column :customers, :postcode, :string
    add_column :customers, :country, :string

    add_column :customers, :address, :text
    add_column :customers, :latitude, :float
    add_column :customers, :longitude, :float
  end
end
