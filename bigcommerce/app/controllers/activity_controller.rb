require 'activity_helper.rb'

# The replacement of task controller
class ActivityController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true
  autocomplete :customer, :actual_name, full: true
  autocomplete :customer_lead, :firstname, full: true
  autocomplete :contact, :name, display_value: :display_position, scopes: :sales_force
  autocomplete :staff, :nickname

  include ActivityHelper

  # insert notes
  # following Dropbox -> pages -> Activity
  def add_note
    @customers, @contacts \
      = customer_search(params)

    # activity helper -> get the functions/subjects/methods from json request
    @function, @subjects = function_search(params)
    # @products = product_search
    @note = Task.new
    if params[:note_id] && Task.where('tasks.id = ?', params[:note_id]).count > 0
      @note.parent_task = params[:note_id]
      @parent = Task.find(@note.parent_task)
    end

    # TEST VERSION
    # @products = Product.sample_products(35, 20)

    @search_text = params[:product_search_text] || nil

    @product_selected = params[:product_selected] || nil

    @customer_text = params[:customer_search_text] || nil

    @selected_method = params[:selected_method] || 'Meeting'
    # production version
    if 'Sales Executive' == session[:authority]
      @products = Product.sample_products(session[:user_id], 20)
    else
      @products = Product.sample_products(35, 20)
    end
  end

  def save_note
    note = note_save(note_params, session[:user_id])
    product_note_save(params, session[:user_id], note.id)
    relation_save(params, note)
    flash[:success] = 'Note Saved!'
    if 'new_task' == params[:button]
      redirect_to action: 'add_activity', note_id: note.id
      return
    end
    redirect_to :back
  end

  # insert task
  # following Dropbox -> pages -> Activity
  def add_activity

    @task = Task.new
    parent_function = nil
    if params[:note_id]
      parents = Task.where('tasks.id = ?', params[:note_id])
      if parents.count > 0
        parent = parents.first
        parent_function = parent.function
        parent_relation = parent.task_relations
        @task.parent_task = params[:note_id]
        @wine_note_list = ProductNote.filter_task(params[:note_id])
      end
    end
    @parent = parent

    @default_method = (parent.nil?) ? 'Meeting' : parent.method
    @default_subject = (parent.nil?) ? nil : parent.subject_1
    @default_customers = (parent.nil?) ? nil : Customer.filter_by_ids(parent_relation.map(&:customer_id).uniq.compact)
    @default_customers = Customer.filter_by_ids([params[:customer_id]]) if params[:customer_id] && @default_customers.nil?
    @default_staff = (parent.nil?) ? [session[:user_id]] : parent_relation.map(&:staff_id).append(session[:user_id]).append(parent.response_staff).uniq.compact

    @function, @subjects = function_search(params, parent_function)
    @staff = Staff.active


      # @products = Product.sample_products(session[:user_id], 20)
      if %w['Sales Executive'].include? session[:authority]
        @products = Product.sample_products(session[:user_id], 20)
      else
        @products = Product.sample_products(35, 20)
      end

    @staff_text = params[:staff_search_text]
  end

  def save_task
    task = note_save(note_params, session[:user_id])
    customer_id = relation_save(params, task)
    task_product_note(params, task, session[:user_id])
    flash[:success] = 'Task Saved!'
    redirect_to controller: 'customer', action: 'summary', customer_id: customer_id, customer_name: Customer.find(customer_id).actual_name
  end

  def activity_edit
    @activity = Task.find(params[:note_id])
    if @activity.nil?
      flash[:error] = 'Error'
      redirect_to :back
    end
    @function, @subjects = function_search(params)
    @staff = Staff.active
    if 'Sales Executive' == session[:authority]
      @products = Product.sample_products(session[:user_id], 20)
    else
      @products = Product.sample_products(35, 20)
    end
  end

  def update
    activity = note_update(note_params, session[:staff_id], params[:activity_id])
    customer_id = relation_save(params, activity)

    task_product_note(params, activity, session[:user_id])
    redirect_to controller: 'customer', action: 'summary', customer_id: customer_id, customer_name: Customer.find(customer_id).actual_name
  end

  # -----------private --------------------
  private

  def note_params
    params.require(:task).permit(:description, :subject_1, :function, :method,\
                                 :promotion_id, :portfolio_id, :start_date, \
                                 :end_date, :priority)
  end
end
