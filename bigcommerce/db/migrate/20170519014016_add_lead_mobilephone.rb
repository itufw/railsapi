class AddLeadMobilephone < ActiveRecord::Migration
  def change
    add_column :customer_leads, :mobile_phone, :text
  end
end
