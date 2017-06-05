class TaskRelationLeads < ActiveRecord::Migration
  def change
    add_column :task_relations, :customer_lead_id, :integer
  end
end
