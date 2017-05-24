class LeadWebsiteImg < ActiveRecord::Migration
  def change
    add_column :customer_leads, :website, :text
    add_column :customer_leads, :img, :text
  end
end
