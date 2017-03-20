module TaskHelper
    def new_task_record(params, current_user, selected_orders)
        if (params[:task][:description] != '') && params[:task][:subject_1]
            t = Task.new
            # format of id: staffID + Customer ID + is task + timestamp
            t.id = Time.now.to_i

            t.start_date = DateTime.strptime(params[:start_time],'%m/%d/%Y %l:%M %P')
            t.end_date = DateTime.strptime(params[:due_time],'%m/%d/%Y %l:%M %P')

            t.is_task = (params[:is_task] == "Task") ? 1 : 0
            t.response_staff = current_user
            t.last_modified_staff = current_user
            t.method = params[:task][:method]
            t.function = params[:task][:function]
            t.subject_1 = params[:task][:subject_1]
            t.description = params[:task][:description]
            t.priority = params[:task][:priority].to_i
            t.parent_task = ((params[:parent_task] != 0) && (params[:parent_task].to_i.to_s == params[:parent_task]))? params[:parent_task] : 0
            # automatically add the parent task to new task
            unless ''.eql? selected_orders
                parent_tasks = OrderAction.where('order_actions.order_id IN (?) AND task_id IS NOT NULL', selected_orders.split).order('created_at DESC')
                unless parent_tasks.nil? || (params[:parent_task] == 0) || parent_tasks.blank?
                    t.parent_task = parent_tasks.first.task_id
                end
                selected_orders.split.each do |order|
                    add_order_action(order.to_i, t.id, t.is_task)
                end
            end
            Task.new.insert_or_update(t)
            customer_id = params['customer']['id'] != '' ? params['customer']['id'] : 0
            staff_id = params['staff']['id'] != '' ? params['staff']['id'] : 0
            TaskRelation.new.insert_or_update(t.id, customer_id, staff_id)

            return t.id
        end
        return 0
    end

    def add_order_action(order_id, task_id, is_task)
        order_action = OrderAction.new
        order_action.order_id = order_id
        order_action.task_id = task_id
        order_action.action = 1 == is_task ? 'task' : 'note'
        order_action.save!
    end

    def note_find_parent(note)
        unless note.parent.nil?
            @notes.unshift(note.parent)
            note_find_parent(note.parent)
        end
    end

    def expire_task(task_id)
        task = Task.find(task_id)
        return if task.nil?
        task.expired = 1
        task.save!
    end

    def reactive_task(task_id)
        task = Task.find(task_id)
        return if task.nil?
        task.expired = 0
        task.save!
    end

    def higher_priority_task(task_id)
        task = Task.find(task_id)
        return if task.nil?
        task.priority = (task.priority.nil?)? 4 : (task.priority + 1)
        task.priority = (task.priority > 5)? 5 : task.priority
        task.save!
    end

    def lower_priority_task(task_id)
        task = Task.find(task_id)
        return if task.nil?
        task.priority = (task.priority.nil?)? 2 : (task.priority - 1)
        task.priority = (task.priority < 1 )? 1 : task.priority
        task.save!
    end

    def complete_task(task_id, staff_id)
        task = Task.find(task_id)
        return if task.nil?
        task.expired = 1
        task.completed_date = Time.now.to_s(:db)
        task.completed_staff = staff_id
        task.save!
    end

    def staff_function(staff_id)
      staff = Staff.find(staff_id)
      case staff.user_type
      when "Sales Executive"
        function = TaskSubject.distinct_function_user("Sales Executive")
      when "Accounts"
        function = TaskSubject.distinct_function
      when "Management"
        function = TaskSubject.distinct_function
      when "Admin"
        function = TaskSubject.distinct_function
      else
        function = TaskSubject.distinct_function
      end
      function
    end

    def staff_task_display(params, user_id)
      task_selected_display = params[:display_options]
      priority = params[:selected_priority]
      subject = params[:selected_subject]
      method = params[:selected_method]
      staff_created = params[:selected_staff_created]
      customers = params[:selected_customer]
      staff = params[:selected_staff]

      case task_selected_display
      when nil || "All"
        tasks = Task.active_tasks.staff_tasks(user_id)
      when "Task"
        tasks = Task.active_tasks.is_task.staff_tasks(user_id)
      when "Note"
        tasks = Task.active_tasks.is_note.staff_tasks(user_id)
      when "Expired All"
        tasks = Task.staff_tasks(user_id)
      end

      tasks = tasks.filter_by_params(priority, subject, method, staff_created, customers, staff)

      tasks = tasks.order_by_id('DESC')
      tasks
    end
end
