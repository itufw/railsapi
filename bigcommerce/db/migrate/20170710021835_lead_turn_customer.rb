class LeadTurnCustomer < ActiveRecord::Migration
  def change
    add_column :customer_leads, :customer_id, :integer
    add_column :customer_leads, :turn_customer_date, :datetime
  end
end
