class AddUpdateToStaff < ActiveRecord::Migration
  def change
  	add_column :staffs, :can_update, :integer, limit: 1, index: true
  end
end
