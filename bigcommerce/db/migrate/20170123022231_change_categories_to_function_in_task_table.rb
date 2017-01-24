class ChangeCategoriesToFunctionInTaskTable < ActiveRecord::Migration
  def change
    remove_column :tasks, :categorise
    add_column :tasks, :function, :string, index: true
  end
end
