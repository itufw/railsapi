class ChangeTaskTableRelationColumn < ActiveRecord::Migration
  def change
    remove_column :task_relations, :type

    add_column :task_relations, :completed_date, :datetime, index: true
    add_column :task_relations, :completed_staff, :integer, index: true

  end
end
