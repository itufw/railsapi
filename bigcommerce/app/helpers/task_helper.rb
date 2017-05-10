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
            t.gcal_status = ("yes".eql? params[:event_column]) ? "pushed" : "na"

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

            t.google_event_id = push_event_to_calendar(customer_id, t.description, staff_id, t.response_staff, t.start_date, t.end_date, t.subject_1, t.method).id if "yes".eql? params[:event_column]

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

    def staff_task_display(params, user_id)
      task_selected_display = params[:display_options]
      priority = params[:selected_priority]
      subject = params[:selected_subject]
      method = params[:selected_method]
      staff_created = params[:selected_staff_created]
      customers = params[:selected_customer]
      staff = params[:selected_staff]

      case task_selected_display
      when "All"
        tasks = Task.active_tasks.staff_tasks(user_id)
      when "Task"
        tasks = Task.active_tasks.is_task.staff_tasks(user_id)
      when "Note"
        tasks = Task.active_tasks.is_note.staff_tasks(user_id)
      when "Expired All"
        tasks = Task.staff_tasks(user_id)
      else
        tasks = Task.active_tasks.staff_tasks(user_id)
      end

      tasks = tasks.filter_by_params(priority, subject, method, staff_created, customers, staff)

      tasks = tasks.order_by_id('DESC')
      tasks
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

    def push_event_to_calendar(customer_id, description, staff, response_staff, start_time, end_time, subject, method)
      client = Signet::OAuth2::Client.new(client_id: Rails.application.secrets.google_client_id,
                                          client_secret: Rails.application.secrets.google_client_secret,
                                          token_credential_uri: 'https://accounts.google.com/o/oauth2/token')

      client.update!(
        :additional_parameters => {"access_type" => "offline"}
        )
      client.update!(session[:authorization])



      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client

      response_staff = Staff.find(response_staff)
      response_staff_email = response_staff.email
      assigned_staff = (staff==0)? response_staff : Staff.find(staff)

      customer = Customer.where("customers.id = #{customer_id}")
      customer = (customer.blank?) ? assigned_staff.nickname : customer.first.actual_name

      address = combine_adress(Address.where("customer_id = #{customer_id}"))
      task_subject = TaskSubject.find(subject).subject

      event = Google::Apis::CalendarV3::Event.new({
                                                  # start: Google::Apis::CalendarV3::EventDateTime.new(date: start_time),
                                                  start: {
                                                    date_time: start_time.strftime('%Y-%m-%dT%H:%M:%S'),
                                                    time_zone: 'Australia/Melbourne',
                                                  },
                                                  # end: Google::Apis::CalendarV3::EventDateTime.new(date: end_time),
                                                  end:{
                                                    date_time: end_time.strftime('%Y-%m-%dT%H:%M:%S'),
                                                    time_zone: 'Australia/Melbourne',
                                                  },
                                                  # colorID: "2",
                                                  summary: task_subject + ": "+ customer,
                                                  description: description,
                                                  location: address,
                                                  attendees: [
                                                    {
                                                      displayName: assigned_staff.nickname,
                                                      email: assigned_staff.email
                                                    }
                                                  ]})
                                                  # attendees: Google::Apis::CalendarV3::EventAttendee.new(email: Staff.find(staff).email)})


      begin
        gcal_event = service.insert_event(response_staff_email, event, send_notifications: true)
        return gcal_event
      rescue Google::Apis::AuthorizationError => exception
        client.update!(
          additional_parameters: {
            grant_type: "refresh_token"
          }
        )
          response = client.refresh!
          session[:authorization] = session[:authorization].merge(response)
          retry
      end
    end

    def combine_adress(customer_address)
      location = ""

      return location if customer_address.nil? || customer_address.blank?
      customer_address = customer_address.first

      location += customer_address.street_1 + " "
      location += customer_address.street_2 + " " unless customer_address.street_2.nil?
      location += ", " + customer_address.city + ", " + customer_address.state + ", " + customer_address.country
      location
    end

    def lock_customer(params)
      parent_task = params[:parent_task] || 0
      if parent_task != 0
          parent_task = Task.joins(:task_relations).find(parent_task)
          customer_locked = true
          customers = Customer.filter_by_ids(parent_task.task_relations.map{|x| x.customer_id}.uniq) unless parent_task.task_relations.blank?
      elsif params[:account_customer].nil? || params[:account_customer].blank?
        customers = Customer.filter_by_staff(params[:selected_staff])
        customer_locked = false
      else
        customers = Customer.filter_by_ids(params[:account_customer])
        customer_locked = true
      end
      [parent_task,customers,customer_locked]
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
end
