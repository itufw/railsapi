class TaskRelation < ActiveRecord::Base
  belongs_to :task
  belongs_to :staff
  belongs_to :customer
  belongs_to :contact
  belongs_to :cust_group

  def self.filter_by_staff_id(staff_id)
    where(staff_id: staff_id)
  end
end
