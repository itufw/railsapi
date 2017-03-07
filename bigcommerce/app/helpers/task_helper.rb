module TaskHelper

    def new_task_record(params, current_user)

        if ((params[:task][:description] != '') && params[:task][:subject_1])
            t = Task.new
            # format of id: staffID + Customer ID + is task + timestamp
            t.id = Time.now.to_i
            # start_date = return_start_date_invoices(params[:start_date])
            # end_date = return_end_date_invoices(params[:end_date])
            start_date = Date.today
            end_date = Date.today
            t.is_task = params[:is_task]
            t.response_staff = current_user
            t.last_modified_staff = current_user
            t.method = params[:task][:method]
            t.function = params[:task][:function]
            t.subject_1 = params[:task][:subject_1]
            t.description = params[:task][:description]
            t.parent_task = params[:parent_task] if params[:parent_task]!=0

            if 1 == t.is_task
                Task.new.insert_or_update(t, start_date, end_date)
                customer_id = (params['customer']['id'] != '') ? params['customer']['id'] : 0
                staff_id = (params['staff']['id'] != '') ? params['staff']['id'] : 0
                TaskRelation.new.insert_or_update(t.id,customer_id, staff_id)
            else
                Task.new.insert_or_update_note(t, start_date)
            end
            return true
        end
        return false
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

    def complete_task(task_id, staff_id)
      task = Task.find(task_id)
      return if task.nil?
      task.expired = 1
      task.completed_date = Time.now.to_s(:db)
      task.completed_staff = staff_id
      task.save!
    end
end
