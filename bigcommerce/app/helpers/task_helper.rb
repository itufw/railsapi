module TaskHelper

    def new_task_record(params, current_user)

        if ((params[:description] != '') && params[:function] && params[:function][:function_name]!="" && params[:subject_id] && params[:subject_id][:id]!="")
            t = Task.new
            # format of id: staffID + Customer ID + is task + timestamp
            t.id = Time.now.to_i
            # start_date = return_start_date_invoices(params[:start_date])
            # end_date = return_end_date_invoices(params[:end_date])
            start_date = Date.today
            end_date = Date.today
            t.description = params[:description]
            t.is_task = params[:is_task]
            t.response_staff = current_user
            t.last_modified_staff = current_user
            t.method = params[:method]
            t.function = params[:function][:function_name]
            t.subject_1 = params[:subject_id][:id]

            if 1 == t.is_task

                Task.new.insert_or_update(t, start_date, end_date)

                relation = TaskRelation.new
                if 'customer'.eql? params[:relation]
                    relation.task_id = t.id
                    relation.customer_id = params['customer']['id']
                    TaskRelation.new.insert_or_update(relation, 'customer')
                else
                    relation.task_id = t.id
                    relation.staff_id = params['staff']['id']
                    TaskRelation.new.insert_or_update(relation, 'staff')
                end
            else
                Task.new.insert_or_update_note(t, start_date)
            end
            return true
        end
        return false
    end
end
