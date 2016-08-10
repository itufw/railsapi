class AddColumnToStatus < ActiveRecord::Migration
  def change
  	add_column :statuses, :valid_order, :integer, limit: 1
  end
end
