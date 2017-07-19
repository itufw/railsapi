require 'models_filter.rb'
require 'dates_helper.rb'
require 'task_helper.rb'

# Task controller -> includes Task helper and add tasks
class TaskController < ApplicationController
  before_action :confirm_logged_in
  autocomplete :customer, :actual_name, full: true

  include ModelsFilter
  include DatesHelper
  include TaskHelper

  def add_task
    # task helper -> check if the customer has assigned
    @parent_task, @customers, @customer_locked, @leads = lock_customer(params)

    @task = Task.new

    @staffs = Staff.active.order_by_order
    @current_user = Staff.find(session[:user_id])

    # task helper -> get the functions/subjects/methods from json request
    @function, @subjects, @methods, @default_function = function_subjects_method(params, @current_user)

    # for some sepcial input
    @selected_orders = params[:selected_invoices] || []
  end

  def staff_task
    @start_date = params[:start_date] ? params[:start_date].split('-').reverse.join('-') : (Date.today.beginning_of_week - 1.week).to_s
    @end_date = params[:end_date] ? params[:end_date].split('-').reverse.join('-') : Date.today.end_of_week.to_s
    @date_column = params[:date_column] || 'start_date'
    @per_page = params[:per_page] || Task.per_page

    @subjects = TaskSubject.all


    @selected_display = params[:display_options] || 'All'
    @tasks, @selected_creator, @selected_assigned = \
      staff_task_display(params, @selected_display, @date_column, @start_date, @end_date, @per_page)
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

    if (params[:task][:is_task] == 1) && params[:staff][:id].blank? && params[:customer][:id].blank?
      flash[:error] = 'Select the Receiver!'
    elsif params[:task][:method].nil? || params[:task][:method].blank?
      flash[:error] = 'Select the Method!'
    elsif params[:task][:subject_1].nil? || params[:task][:subject_1].blank?
      flash[:error] = 'Select the Subject!'
    else
      # in the Task Helper
      # create new row for the task
      # return task id or 0
      parent_task_id = new_task_record(params, session[:user_id], selected_orders)
      if parent_task_id > 0
        flash[:success] = 'Created new Task!'
        if ''.eql? params[:button]
          params[:accounts_page] && !(''.eql? params[:customer][:id]) ? (redirect_to(controller: 'accounts', action: 'contact_invoices', customer_id: params[:customer][:id]) && return) : (redirect_to(action: 'staff_task') && return)
        else
          selected_invoices = params[:selected_orders].nil? ? [] : params[:selected_orders].split
          account_customer = (!params[:customer].nil? && params[:customer][:id] != '') ? params[:customer][:id] : 0
          redirect_to(controller: 'task', action: 'add_task',\
                      parent_task: parent_task_id, account_customer: account_customer,\
                      selected_invoices: selected_invoices, selected_function: params[:task][:function]) && return
        end
      else
        flash[:error] = 'Fill the form!'
      end
    end
    redirect_to :back
  end

  def task_update
    begin
      case params[:task_type]
      when 'expired'
        Task.find(params[:task_id]).expire_task
      when 'reactive'
        Task.find(params[:task_id]).reactive_task
      when 'higher_priority'
        higher_priority_task(params[:task_id])
      when 'lower_priority'
        lower_priority_task(params[:task_id])
      when 'completed'
        Task.find(params[:task_id]).complete_task(session[:user_id])
      end
    rescue
      flash[:error] = "Error"
    end
    redirect_to :back
  end

  def update_priority
    task_id = params[:task_id]
    priority = params[:priority]

    Task.priority_change(task_id, priority)

    flash[:success] = 'Priority Successfully Changed.'
    redirect_to request.referrer
  end
end
