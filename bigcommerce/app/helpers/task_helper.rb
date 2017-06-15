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
            t.gcal_status = ("yes".eql? params[:event_column]) ? "pending" : "na"

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
            customer_id = params['customer']['id'] != '' ? params['customer']['id'] : 0
            staff_id = params['staff']['id'] != '' ? params['staff']['id'] : 0


            Task.new.insert_or_update(t)
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

    def staff_task_display(params, task_selected_display)

      selected_staff = (params[:staff] && params[:staff][:assigned] && !params[:staff][:assigned]=='') ? [params[:staff][:assigned]] : Staff.active.map(&:id)

      selected_creator = (params[:staff] && params[:staff][:creator]) ? [params[:staff][:creator]] : [session[:user_id]]
      selected_creator = Staff.active.map(&:id) if selected_creator == ['']
      order = 'DESC'

      date_column = params[:date_column] || 'start_date'
      start_date = params[:start_date] ? params[:start_date].split('-').reverse.join('-') : (Date.today - 1.month).to_s
      end_date = params[:end_date] ? params[:end_date].split('-').reverse.join('-') : Date.today.to_s

      task_relations = TaskRelation.filter_by_staff_ids(selected_staff)

      case task_selected_display
      when "Task"
        tasks = Task.active_tasks.is_task
      when "Note"
        tasks = Task.active_tasks.is_note
      when "Expired All"
        tasks = Task.all
      else
        tasks = Task.active_tasks
      end

      tasks = tasks.filter_by_responses(selected_creator).filter_by_ids(task_relations.map(&:task_id)).send('filter_by_' + date_column, start_date, end_date).send('order_by_' + date_column, order)
      [tasks, collection_default_staff(selected_creator), collection_default_staff(selected_staff)]
    end

    def collection_default_staff(staffs)
      return 0 if staffs.count > 1
      staffs.first
    end

    def default_function_type(user_role)
      case user_role
      when "Accounts"
        role = "Accounting"
      when "Sales Executive"
        role = "Sales"
      when "Admin"
        role = "Operations"
      else
        role = "Operations"
      end
      role
    end


    def lock_customer(params)
      parent_task = params[:parent_task] || 0
      leads = CustomerLead.all
      if parent_task != 0
        parent_task = Task.joins(:task_relations).find(parent_task)
        customer_locked = true
        customers = Customer.filter_by_ids(parent_task.task_relations.map{|x| x.customer_id}.uniq) unless parent_task.task_relations.blank?
      elsif params[:account_customer].nil? || params[:account_customer].blank?
        customers = Customer.filter_by_staff(params[:selected_staff])
        leads = CustomerLead.filter_staff(params[:selected_staff])
        customer_locked = false
      else
        customers = Customer.filter_by_ids(params[:account_customer])
        customer_locked = true
      end
      [parent_task, customers, customer_locked, leads]
    end

    def function_subjects_method(params, current_user)
      function = staff_function(session[:user_id])
      # Sales/ Operations/ Accounting
      default_function = default_function_type(current_user.user_type)
      params[:selected_function] = params[:selected_function].nil? ? default_function : params[:selected_function]

      subjects = TaskSubject.all
      subjects = subjects.select { |x| x.function == params[:selected_function] }
      methods = TaskMethod.all
      [function, subjects, methods, default_function]
    end

    # task_display_hepler
    def task_customer_staff(task_relation)
      return ['-', '-'] if task_relation.nil? || task_relation.blank?

      customer = task_relation.map(&:customer_id).compact.uniq
      customer.delete(0)
      staff = task_relation.map(&:staff_id).compact.uniq
      staff.delete(0)

      customer = (customer.blank?) ? '-' : Customer.filter_by_ids(customer)
      staff = (staff.blank?) ? '-' : Staff.filter_by_ids(staff)
      [customer, staff]
    end
end
