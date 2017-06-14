class TaskRelation < ActiveRecord::Base
  belongs_to :task
  belongs_to :staff
  belongs_to :customer
  belongs_to :contact
  belongs_to :cust_group
  belongs_to :customer_lead

  def insert_or_update(task_id, customer_id, staff_id)
    time = Time.now.to_s(:db)

    r = "('#{task_id}','#{customer_id}','#{staff_id}','#{time}','#{time}')"
    sql = "INSERT INTO `task_relations`(`task_id`, `customer_id`,`staff_id`,\
          `created_at`, `updated_at`) VALUES #{r}"
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.filter_by_staff_id(staff_id)
    where(staff_id: staff_id)
  end

  def self.filter_by_staff_ids(staff_ids)
    where('staff_id IN (?)', staff_ids)
  end

  def self.filter_by_task_ids(task_ids)
    where('task_id IN (?)', task_ids)
  end

  def link_relation(task_id, customer_id, staff_id = nil)
    time = Time.now.to_s(:db)

    return if customer_id.nil? && staff_id.nil?

    task_relation = TaskRelation.new

    task_relation.task_id = task_id

    unless customer_id.nil?
      id, actual_name = customer_id.split('|')
      customer = Customer.where("id = #{id}").first
      if !customer.nil? && customer.actual_name == actual_name
        task_relation.customer_id = id
      else
        task_relation.customer_lead_id = id
      end
    end
    task_relation.staff_id = staff_id unless staff_id.nil?
    task_relation.created_at = time
    task_relation.updated_at = time
    task_relation.save
  end
end
