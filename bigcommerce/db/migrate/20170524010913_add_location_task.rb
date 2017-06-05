# Include Location in tasks
# for google events
class AddLocationTask < ActiveRecord::Migration
  def change
    add_column :tasks, :location, :text
    add_column :tasks, :summary, :text
  end
end
