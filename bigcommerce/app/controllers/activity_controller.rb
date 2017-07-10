require 'activity_helper.rb'

# The replacement of task controller
class ActivityController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true
  autocomplete :customer, :actual_name, full: true
  autocomplete :customer_lead, :actual_name, full: true, scopes: :not_customer
  autocomplete :contact, :name, display_value: :display_position
  autocomplete :staff, :nickname, extra_data: [:nickname]

  include ActivityHelper

  # insert notes
  # following Dropbox -> pages -> Activity
  def add_note
    @customers, @contacts \
      = customer_search(params)

    @note = Task.new
    if params[:note_id] && Task.where('tasks.id = ?', params[:note_id]).count > 0
      @note.parent_task = params[:note_id]
      @parent = Task.find(@note.parent_task)
      @completed_parent = params[:task_type] || 'no'

      @note.function = @parent.function
      @note.subject_1 = @parent.subject_1
      @note.promotion_id = @parent.promotion_id
      @note.portfolio_id = @parent.portfolio_id
    else
      @note.method = params[:selected_method] || 'Meeting'
      @note.function = default_function_type(session[:authority])
      @note.subject_1 = 0
      @note.promotion_id = 0
      @note.portfolio_id = 0
    end


    # activity helper -> get the functions/subjects/methods from json request
    @function, @subjects = function_search(params, @parent)

    # Sample products from table
    # ['tr_1000','tr_2000']
    @sample_products = params[:sample_products] || nil

    @search_text = params[:product_search_text] || nil

    @product_selected = params[:product_selected] || nil

    @customer_text = params[:customer_search_text] || nil

    @lead_text = params[:lead_search_text] || nil
  end

  def save_note
    note = note_save(note_params, session[:user_id])

    # complted: task_control_icon -> add_note -> save_note
    if note.parent_task && params[:completed_parent] == 'completed'
      parent = Task.find(note.parent_task)
      parent.expired = 1
      parent.completed_date = Date.today.to_s(:db)
      parent.completed_staff = session[:user_id]
      parent.save
    end

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
    if params[:note_id]
      parents = Task.where('tasks.id = ?', params[:note_id])
      if parents.count > 0
        parent = parents.first
        @task.parent_task = params[:note_id]
        @wine_note_list = ProductNote.filter_task(params[:note_id])
      end
    end
    @parent = parent

    @function, @subjects = function_search(params, @parent)
    @staff = Staff.active
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
  end

  def update
    activity = note_update(note_params, session[:staff_id], params[:activity_id])
    customer_id, destination = relation_save(params, activity)

    task_product_note(params, activity, session[:user_id])
    if destination == 'customer'
      redirect_to controller: 'customer', action: 'summary', customer_id: customer_id, customer_name: Customer.find(customer_id).actual_name
      return
    end

    redirect_to controller: 'lead', action: 'summary', lead_id: customer_id
  end

  def autocomplete_product_name
    products = Product.search_for(params[:term]).order('name_no_vintage ASC, vintage DESC').all
    render :json => products.map { |product| {:id => product.id, :label => product.name, :value => product.name, :price => (product.calculated_price * (1.29)).round(2)} }
  end

  # -----------private --------------------
  private

  def note_params
    params.require(:task).permit(:description, :subject_1, :function, :method,\
                                 :promotion_id, :portfolio_id, :start_date, \
                                 :end_date, :priority)
  end
end
