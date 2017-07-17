class CustomerTagSalesToStaff < ActiveRecord::Migration
  def change
    remove_column :customer_tags, :sales
    add_column :customer_tags, :staff, :string
  end
end
