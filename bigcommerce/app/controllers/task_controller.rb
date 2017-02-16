require 'models_filter.rb'
require 'dates_helper.rb'
require 'task_helper.rb'
class TaskController < ApplicationController
  before_action :confirm_logged_in

  include ModelsFilter
  include DatesHelper
  include TaskHelper

  def add_task
    @start_date = return_start_date_invoices(params[:start_date])
    @end_date = return_end_date_invoices(params[:end_date])
    @user_type  = Staff.find(session[:user_id]).user_type

    @customers_xero_contact = XeroContact.outstanding_is_greater_zero
    # @subjects = TaskSubject.get_subjects(params[:function_name])


    if (("1".eql? params[:is_task]) &&params[:relation])
      if params[params[:relation]][:id] == ""
        flash[:error] = "Select the receiver!"
        redirect_to :back
      else
        # in the Task Helper
        # create new row for the task
        if new_task_record(params,session[:user_id])
          flash[:success] = "Created new Note!"
        else
          flash[:error] = "Fill the form!"
        end
        redirect_to :back
      end
    end

    if "0".eql? params[:is_task]
      if new_task_record(params,session[:user_id])
        flash[:success] = "Created new Note!"
      else
        flash[:error] = "Fill the form!"
      end
      redirect_to :back
    end

  end
end
