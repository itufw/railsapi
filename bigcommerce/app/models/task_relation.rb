class TaskRelation < ActiveRecord::Base
  belongs_to :task
  belongs_to :staff
  belongs_to :customer
  belongs_to :contact
  belongs_to :cust_group

  def insert_or_update(relation,target)
    time = Time.now.to_s(:db)

    if "customer".eql? target
      r = "(#{relation.task_id},#{relation.customer_id},'#{time}','#{time}')"

    sql = "INSERT INTO `task_relations`(`task_id`, `customer_id`,`created_at`, `updated_at`)\
          VALUES #{r}"
    else
      r = "(#{relation.task_id},#{relation.staff_id},#{time},#{time})"
      sql = "INSERT INTO `task_relations`(`task_id`,`staff_id`, `created_at`, `updated_at`)\
                VALUES #{r}"
    end
    ActiveRecord::Base.connection.execute(sql)

  end

  def self.filter_by_staff_id(staff_id)
    where(staff_id: staff_id)
  end
end
