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

    @methods = TaskMethod.all
    if (params[:account_customer].nil? || params[:account_customer].blank?)
      @staffs = Staff.active
      @customers = Customer.filter_by_staff(params[:selected_staff])
      @customer_locked = false
    else
      @customers = Customer.filter_by_ids(params[:account_customer])
      @staffs = Staff.where("id IN (?)", @customers.map {|x| x.staff_id})
      @customer_locked = true
    end

    @start_date = return_start_date_invoices(params[:start_date])
    @end_date = return_end_date_invoices(params[:end_date])
  end

  def staff_task
    @tasks = Task.active_tasks.staff_tasks(session[:user_id]).order_by_id("DESC")
    @subjects = TaskSubject.all
  end

  def task_record
    if ("1".eql? params[:is_task])
      if (params[:staff][:id].blank? && params[:customer][:id].blank?)
        flash[:error] = "Select the Receiver!"
      elsif (params[:task][:method].nil? || params[:task][:method].blank?)
        flash[:error] = "Select the Method!"
      elsif (params[:task][:subject_1].nil? || params[:task][:subject_1].blank?)
        flash[:error] = "Select the Subject!"
      else
        # in the Task Helper
        # create new row for the task
        if new_task_record(params,session[:user_id])
          flash[:success] = "Created new Task!"
        else
          flash[:error] = "Fill the form!"
        end
      end
    end

    if "0".eql? params[:is_task]
      if (params[:task][:subject_1].nil? || params[:task][:subject_1].blank?)
        flash[:error] = "Select the Subject!"
      elsif new_task_record(params,session[:user_id])
        flash[:success] = "Created new Note!"
      else
        flash[:error] = "Fill the form!"
      end
    end
    redirect_to :back
  end
end
