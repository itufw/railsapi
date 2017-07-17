class CustomerTagStaffRename < ActiveRecord::Migration
  def change
    remove_column :customer_tags, :staff
    add_column :customer_tags, :staff_nickname, :string
  end
end
