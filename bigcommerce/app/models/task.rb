class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations

  def insert_or_update(t,start_date,end_date)
    time = Time.now.to_s(:db)

    task = "(#{t.id},'#{start_date}', '#{end_date}', '#{time}', '#{time}', '#{t.title}', '#{t.description}', #{t.is_task},\
            #{t.response_staff}, #{t.last_modified_staff}, '#{t.method}', '#{t.function}','#{t.subject_1}', 0)"
    sql = "INSERT INTO `tasks`(`id`,`start_date`, `end_date`, `created_at`, `updated_at`,\
          `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
          `function`, `subject_1`, `expired`)\
          VALUES #{task}"

    ActiveRecord::Base.connection.execute(sql)
  end


  def insert_or_update_note(t,start_date)
    time = Time.now.to_s(:db)

    task = "(#{t.id},'#{start_date}', '#{start_date}', '#{time}', '#{time}', '#{t.description}', #{t.is_task},\
            #{t.response_staff}, #{t.last_modified_staff}, '#{t.function}', '#{t.subject_1}', 0)"

    sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
          `description`, `is_task`, `response_staff`, `last_modified_staff`,\
          `function`, `subject_1`, `expired`)\
          VALUES #{task}"

    ActiveRecord::Base.connection.execute(sql)
  end

  def auto_insert_from_mailer(email_type, customer_id, staff_id)
    time = Time.now.to_s(:db)
    end_time = (Time.now+1.month).to_s(:db)

    description = "Send #{email_type}"
    case email_type
    when 'Send Reminder', 'Send Missed Payment'
      subject = 18
    when 'Send Overdue Reminder'
      subject = 19
    when 'Send 60 Days Overdue Reminder'
      subject = 20
    when 'Send 90 Days Overdue Reminder'
      subject = 21
    else
      subject = 19
    end

    task_id = Time.now.to_i

    task = "(#{task_id},'#{time}', '#{end_time}', '#{time}', '#{time}', '#{description}', 1,\
            #{staff_id}, #{staff_id}, 'Email', 'Accounting', '#{subject}', 0)"
    sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
          `description`, `is_task`, `response_staff`, `last_modified_staff`,\
          `method`, `function`, `subject_1`, `expired`)\
          VALUES #{task}"

    ActiveRecord::Base.connection.execute(sql)

    customer_staff_id = Customer.find(customer_id).staff_id
    TaskRelation.new.insert_or_update(task_id,customer_id, customer_staff_id)
  end

  def self.staff_tasks(staff_id)
    includes(:task_relations).where("tasks.response_staff = '#{staff_id}' or task_relations.staff_id = '#{staff_id}'").references(:task_relations)
  end

  def self.customer_tasks(customer_id)
    includes(:task_relations).where("task_relations.customer_id = '#{customer_id}'").references(:task_relations)
  end

  def self.active_tasks
    where("tasks.expired = 0")
  end

  def self.order_by_id(direction)
      order('tasks.id ' + direction)
  end
end
