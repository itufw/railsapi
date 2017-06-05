# maybe not the best solution
# combine all product notes into one column in task
class AddPnTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :pro_note_include, :string
  end
end
