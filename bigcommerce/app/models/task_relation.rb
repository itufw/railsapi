class TaskRelation < ActiveRecord::Base
  belongs_to :task
  belongs_to :staff
  belongs_to :customer
  belongs_to :contact
  belongs_to :cust_group
end
