class AddFeaturedImageCustomerLead < ActiveRecord::Migration
  def change
    add_column :customers, :featured_image, :text
    add_column :customer_leads, :featured_image, :text
  end
end
