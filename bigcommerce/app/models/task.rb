class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations
end
