class AddPendingToStaff < ActiveRecord::Migration
  def change
  	add_column :staffs, :pending_orders, :integer, limit: 1
  end
end
