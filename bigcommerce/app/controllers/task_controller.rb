require 'models_filter.rb'
require 'dates_helper.rb'
require 'task_helper.rb'
class TaskController < ApplicationController
    before_action :confirm_logged_in

    include ModelsFilter
    include DatesHelper
    include TaskHelper

    def add_task
        @task = Task.new
        @function = TaskSubject.distinct_function
        @subjects = TaskSubject.get_subjects_on_function(params[:selected_function])
        @subjects_task = TaskSubject.get_subjects_on_function(params[:selected_function_task])

        @parent_task = params[:parent_task] || 0

        @methods = TaskMethod.all
        if params[:account_customer].nil? || params[:account_customer].blank?
            @staffs = Staff.active
            @customers = Customer.filter_by_staff(params[:selected_staff])
            @customers_task = Customer.filter_by_staff(params[:selected_staff_task])
            @customer_locked = false
        else
            @customers = Customer.filter_by_ids(params[:account_customer])
            @customers_task = @customers
            @staffs = Staff.active
            @customer_locked = true
        end

        @start_date = return_start_date_invoices(params[:start_date])
        @end_date = return_end_date_invoices(params[:end_date])

        # for some sepcial input
        @selected_orders = params[:selected_invoices] || []
    end

    def staff_task
        @tasks = Task.active_tasks.staff_tasks(session[:user_id]).order_by_id('DESC')
        @subjects = TaskSubject.all
    end

    def task_details
        @note = Task.find(params[:task_id])
        @notes = []
        # find all parent tasks
        # used @notes
        note_find_parent(@note)
        @selected_orders = OrderAction.where('task_id = ?', @note.id).map(&:order_id)
    end

    def task_record
        selected_orders = params[:selected_orders] || ''

        if params[:staff][:id].blank? && params[:customer][:id].blank?
            flash[:error] = 'Select the Receiver!'
        elsif params[:task][:method].nil? || params[:task][:method].blank?
            flash[:error] = 'Select the Method!'
        elsif params[:task][:subject_1].nil? || params[:task][:subject_1].blank?
            flash[:error] = 'Select the Subject!'
        else
            # in the Task Helper
            # create new row for the task
            if new_task_record(params, session[:user_id], selected_orders)
                flash[:success] = 'Created new Task!'
                params[:accounts_page] && params[:customer][:id] ? redirect_to(controller: 'accounts', action: 'contact_invoices', customer_id: params[:customer][:id]) && return : redirect_to(action: 'staff_task') && return
            else
                flash[:error] = 'Fill the form!'
            end
        end

        redirect_to :back
    end

    def task_update
        task_id = params[:task_id]
        case params[:task_type]
        when 'expired'
            expire_task(params[:task_id])
        when 'reactive'
            reactive_task(params[:task_id])
        when 'higher_priority'
            higher_priority_task(params[:task_id])
        when 'lower_priority'
            lower_priority_task(params[:task_id])
        when 'completed'
            complete_task(params[:task_id], session[:user_id])
        end
        redirect_to :back
    end
end
