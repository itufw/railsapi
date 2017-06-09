class LeadMergeSalesForce < ActiveRecord::Migration
  def change
    add_column :customer_leads, :salesforce_lead_id, :string

    add_column :customer_leads, :street, :string
    add_column :customer_leads, :city, :string
    add_column :customer_leads, :state, :string
    add_column :customer_leads, :postalcode, :string
    add_column :customer_leads, :country, :string


    add_column :customer_leads, :perferred_contact_time, :string
    add_column :customer_leads, :useful_information, :text

  end
end
