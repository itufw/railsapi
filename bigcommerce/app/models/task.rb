class Task < ActiveRecord::Base
  has_many :task_activities
  has_many :task_relations
  has_many :task_priorities
  has_many :order_actions
  has_many :product_notes
  has_one :portfolio
  belongs_to :staff, class_name: 'Staff', foreign_key: :response_staff
  belongs_to :parent, class_name: 'Task', foreign_key: 'parent_task'
  has_many :children, class_name: 'Task', foreign_key: 'parent_task'

  enum gcal_status: %i[na pushed pulled unconfirmed rejected pending]

  self.per_page = 5

  def insert_or_update(t)
    time = Time.now.to_s(:db)
    t.start_date = t.start_date.to_s(:db)
    t.end_date = t.end_date.to_s(:db)
    t.created_at = time
    t.updated_at = time
    t.expired = 0
    t.save
  end

  # Google Calendar insert or update
  def auto_insert_from_calendar_event(event, staff_id)
    task = self
    task.start_date = if event.start.date_time.nil?
                        event.start.date.to_s
                      else
                        event.start.date_time.to_s(:db)
                      end
    task.end_date = if event.end.date_time.nil?
                      event.end.date.to_s
                    else
                      event.end.date_time.to_s(:db)
                    end
    task.created_at = event.created.to_s(:db)
    task.updated_at = event.updated.to_s(:db)
    task.description = event.summary
    task.location = event.location
    task.summary = event.description
    task.is_task = 1

    response_staff = staff_id

    task.response_staff = response_staff
    task.last_modified_staff = response_staff
    task.priority = 3
    task.expired = 1
    task.google_event_id = event.id
    task.gcal_status = :unconfirmed
    task.save
  end

  def auto_update_from_calendar_event(event)
    task = self
    task.start_date = if event.start.date_time.nil?
                        event.start.date.to_s
                      else
                        event.start.date_time.to_s(:db)
                      end
    task.end_date = if event.end.date_time.nil?
                      event.end.date.to_s
                    else
                      event.end.date_time.to_s(:db)
                    end
    task.description = event.summary
    task.location = event.location
    task.summary = event.description
    task.save
  end

  def update_event(event_id, method, subject, customer)
    task = Task.where(google_event_id: event_id)
    return false unless task.count > 0
    customer_id = customer.blank? || customer.nil? ? nil : customer['customer']
    method = method['method']
    subject = subject['subject']

    task = task.first
    task.method = method
    task.subject_1 = subject
    task.function = 'Sales'
    task.expired = 0
    task.gcal_status = :pulled
    task.save

    TaskRelation.new.link_relation(task.id, customer_id) unless customer_id.nil?
    true
  end

  def reject_event(event_id)
    task = Task.where(google_event_id: event_id)
    return false unless task.count > 0
    task = task.first
    task.gcal_status = :rejected
    task.save
    true
  end

  def auto_insert_from_mailer(email_type, customer_id, staff_id, mailer_id, selected_orders)
    time = Time.now.to_s(:db)
    end_time = (Time.now + 1.month).to_s(:db)

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
          `method`, `function`, `subject_1`, `expired`, `priority`)\
          VALUES (#{task_id},'#{time}', '#{end_time}', '#{time}', '#{time}', '#{mailer_id}', \"#{description}\", 0,\
                  #{staff_id}, #{staff_id}, 'Email', 'Accounting', '#{subject}', 0, 3)"

    # add the notes to order level
    selected_orders.each do |s_order|
      order_action = OrderAction.new
      order_action.order_id = s_order.to_i
      order_action.action = 'note'
      order_action.task_id = task_id
      order_action.save!
    end

      # parent_tasks = OrderAction.where("order_actions.order_id = ? AND task_id IS NOT NULL", order.to_i).order("created_at DESC")
      # unless ((parent_tasks.nil?)||(parent_tasks.blank?))
      # sql = "INSERT INTO `tasks`(`id`,`start_date`,`end_date`, `created_at`, `updated_at`,\
      #       `title`, `description`, `is_task`, `response_staff`, `last_modified_staff`,\
      #       `method`, `function`, `subject_1`, `expired`, `priority`)\
      #       VALUES (#{task_id},'#{time}', '#{end_time}', '#{time}', '#{time}', '#{mailer_id}', \"#{description}\", 0,\
      #               #{staff_id}, #{staff_id}, 'Email', 'Accounting', '#{subject}', 0, 3)"
      # end

      # order_action = OrderAction.new
      # order_action.order_id = order.to_i
      # order_action.action = "note"
      # order_action.task_id = task_id
      # order_action.save!
    # end

    ActiveRecord::Base.connection.execute(sql)

    customer_staff_id = Customer.find(customer_id).staff_id
    TaskRelation.new.insert_or_update(task_id, customer_id, customer_staff_id)
  end

  def insert_from_calendar(event)
    task = Task.new
    task.id = Time.now
    task.start_date = event.start.date_time.to_s(:db)
    task.end_date = event.end.date_time.to_s(:db)
    task.created_at = event.created_at.to_s(:db)
    task.updated_at = event.updated.to_s(:db)
    # task.title
    task.description = event.summary.to_s + "\n" + event.description.to_s
    task.is_task = event.attendees.nil? ? 0 : 1

    unless event.attendees.nil?
      event.attendees.each do |attendee|
        staff = Staff.where("staffs.email = #{attendee.email}")
        next unless staff.count > 0
        task_relations = TaskRelation.new
        task_relations.task_id = task.id
        task_relations.staff_id = staff.first.id
        task_relations.created_at = task.created_at
        task_relations.updated_at = task.updated_at
        task_relations.save
      end
    end

    staff = Staff.where("staffs.email = #{event.creator.email}")
    task.response_staff = staff.count > 0 ? staff.first.id : NULL
    task.last_modified_staff = staff.count > 0 ? staff.first.id : NULL

    task.expired = 0
    task.priority = 3

    task.google_event_id = event.id
    task.gcal_status = :pulled
    task.save
  end

  def self.staff_tasks(staff_id)
    includes(:task_relations).where("tasks.response_staff = '#{staff_id}' or task_relations.staff_id = '#{staff_id}'").references(:task_relations).where('tasks.gcal_status <> 3')
  end

  def self.order_tasks(order_id)
    includes(:order_actions).where("order_actions.order_id = '#{order_id}'").references(:order_actions)
  end

  def self.customer_tasks(customer_id)
    includes(:task_relations).where("task_relations.customer_id = '#{customer_id}'").references(:task_relations)
  end

  def self.task_children(task_id)
    where("tasks.parent_task = #{task_id}")
  end

  def self.active_tasks
    where('tasks.expired = 0')
  end

  def self.expired?
    where('tasks.expired != 1')
  end

  def self.is_task
    where('tasks.is_task = 1')
  end

  def self.is_note
    where('tasks.is_task = 0')
  end

  def self.order_by_id(direction)
    order('tasks.id ' + direction)
  end

  def self.order_by_staff(direction)
    order('tasks.response_staff ' + direction)
  end

  def self.filter_by_staff(staff_id)
    includes(:task_relations).where('tasks.response_staff = ? OR task_relations.staff_id = ?', staff_id, staff_id).references(:task_relations)
  end

  def self.filter_by_google_event_id(google_id)
    where('tasks.google_event_id = ? ', google_id)
  end

  def self.unconfirmed_event
    where(gcal_status: 3)
  end

  def self.pending_event
    where(gcal_status: 5)
  end

  def self.filter_by_params(priority, subject, method, staff_created, customers, staff)
    sql = ''
    sql += "tasks.priority in (#{priority.join(',')}) OR " unless priority.nil? || priority.blank?
    sql += "tasks.subject_1 in (#{subject.join(',')}) OR " unless subject.nil? || subject.blank?
    sql += "tasks.method in (\"#{method.join(',')}\") OR " unless method.nil? || method.blank?
    sql += "tasks.response_staff in (#{staff_created.join(',')}) OR " unless staff_created.nil? || staff_created.blank?
    sql += "tasks.id in (#{TaskRelation.select('task_id').where('customer_id IN (?)', customers).map(&:task_id).join(',')}) OR " unless customers.nil? || customers.blank?
    sql += "tasks.id in (#{TaskRelation.select('task_id').where('staff_id IN (?)', staff).map(&:task_id).join(',')}) OR " unless staff.nil? || staff.blank?
    sql = sql[0..-4] unless sql.length < 5
    where(sql)
  end

  def self.priority_change(task_id, priority)
    task = Task.find(task_id)
    task.priority = priority
    task.save!
  end

  # calendar gem requests
  def start_time
    start_date
  end

  def end_time
    end_date
  end
end
