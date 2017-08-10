class CuisinePriorityGroup < ActiveRecord::Migration
  def change
    add_column :zomato_cuisines, :priority_group, :integer
  end
end
