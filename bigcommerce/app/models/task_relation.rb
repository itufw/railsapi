class TaskRelation < ActiveRecord::Base
  belongs_to :task
  belongs_to :staff
  belongs_to :customer
  belongs_to :contact
  belongs_to :cust_group

  def insert_or_update(task_id,customer_id,staff_id)
    time = Time.now.to_s(:db)

    r = "('#{task_id}','#{customer_id}','#{staff_id}','#{time}','#{time}')"
    sql = "INSERT INTO `task_relations`(`task_id`, `customer_id`,`staff_id`,`created_at`, `updated_at`)\
          VALUES #{r}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.filter_by_staff_id(staff_id)
    where(staff_id: staff_id)
  end
end
