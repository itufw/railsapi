class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations
  has_many :order_actions
  belongs_to :parent, :class_name => 'Task', :foreign_key => "parent_task"
  has_many :children, :class_name => 'Task', :foreign_key => "parent_task"

  def insert_or_update(t,start_date,end_date)
    time = Time.now.to_s(:db)

    if t.parent_task != 0
      task = "(#{t.id},'#{start_date}', '#{end_date}', '#{time}', '#{time}', '#{t.title}', '#{t.description}', #{t.is_task},\
              #{t.response_staff}, #{t.last_modified_staff}, '#{t.method}', '#{t.function}','#{t.subject_1}', 0,'#{t.parent_task}')"
      sql = "INSERT INTO `tasks`(`id`,`start_date`, `end_date`, `created_at`, `updated_at`,\
            `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
            `function`, `subject_1`, `expired`, `parent_task`)\
            VALUES #{task}"
    else
      task = "(#{t.id},'#{start_date}', '#{end_date}', '#{time}', '#{time}', '#{t.title}', '#{t.description}', #{t.is_task},\
              #{t.response_staff}, #{t.last_modified_staff}, '#{t.method}', '#{t.function}','#{t.subject_1}', 0)"
      sql = "INSERT INTO `tasks`(`id`,`start_date`, `end_date`, `created_at`, `updated_at`,\
            `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
            `function`, `subject_1`, `expired`)\
            VALUES #{task}"
    end

    ActiveRecord::Base.connection.execute(sql)
  end


  def insert_or_update_note(t,start_date)
    time = Time.now.to_s(:db)
    unless ((t.parent_task.nil?) || ("".eql? t.parent_task) || (t.parent_task == 0))
      task = "(#{t.id},'#{start_date}', '#{start_date}', '#{time}', '#{time}', '#{t.description}', #{t.is_task},\
              #{t.response_staff}, #{t.last_modified_staff}, '#{t.method}', '#{t.function}', '#{t.subject_1}', 0, '#{t.parent_task}')"
      sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
            `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
            `function`, `subject_1`, `expired`,`parent_task`)\
            VALUES #{task}"
    else
      task = "(#{t.id},'#{start_date}', '#{start_date}', '#{time}', '#{time}', '#{t.description}', #{t.is_task},\
              #{t.response_staff}, #{t.last_modified_staff}, '#{t.method}', '#{t.function}', '#{t.subject_1}', 0)"
      sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
            `description`, `is_task`, `response_staff`, `last_modified_staff`, `method`,\
            `function`, `subject_1`, `expired`)\
            VALUES #{task}"
    end

    ActiveRecord::Base.connection.execute(sql)
  end

  def auto_insert_from_mailer(email_type, customer_id, staff_id, mailer_id, selected_orders)
    time = Time.now.to_s(:db)
    end_time = (Time.now+1.month).to_s(:db)

    description = "Sent #{email_type}"
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

    sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
          `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`,\
          `method`, `function`, `subject_1`, `expired`)\
          VALUES (#{task_id},'#{time}', '#{end_time}', '#{time}', '#{time}', '#{mailer_id}', '#{description}', 0,\
                  #{staff_id}, #{staff_id}, 'Email', 'Accounting', '#{subject}', 0)"


    # add the notes to order level
    selected_orders.each do |order|
      parent_tasks = OrderAction.where("order_actions.order_id = ? AND task_id IS NOT NULL", order.to_i).order("created_at DESC")
      unless parent_tasks.nil?
        sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
              `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`,\
              `method`, `function`, `subject_1`, `expired`, `parent_task`)\
              VALUES (#{task_id},'#{time}', '#{end_time}', '#{time}', '#{time}', '#{mailer_id}', '#{description}', 0,\
                      #{staff_id}, #{staff_id}, 'Email', 'Accounting', '#{subject}', 0, #{parent_tasks.first.task_id})"
      end

      order_action = OrderAction.new
      order_action.order_id = order.to_i
      order_action.action = "note"
      order_action.task_id = task_id
      order_action.save!
    end

    ActiveRecord::Base.connection.execute(sql)

    customer_staff_id = Customer.find(customer_id).staff_id
    TaskRelation.new.insert_or_update(task_id,customer_id, customer_staff_id)
  end

  def self.staff_tasks(staff_id)
    includes(:task_relations).where("tasks.response_staff = '#{staff_id}' or task_relations.staff_id = '#{staff_id}'").references(:task_relations)
  end

  def self.order_tasks(order_id)
    includes(:order_actions).where("order_actions.order_id = '#{order_id}'").references(:order_actions)
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
