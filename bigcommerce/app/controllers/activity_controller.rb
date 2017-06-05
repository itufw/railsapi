require 'activity_helper.rb'

# The replacement of task controller
class ActivityController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true
  autocomplete :customer, :actual_name, full: true
  autocomplete :customer_lead, :firstname, full: true
  autocomplete :staff, :nickname

  include ActivityHelper

  # insert notes
  # following Dropbox -> pages -> Activity
  def add_note
    @customers, @contacts \
      = customer_search(params)

    # activity helper -> get the functions/subjects/methods from json request
    @function, @subjects, @methods, @function_role, @promotion, @portfolio \
      = function_search(params)
    # @products = product_search
    @note = Task.new
    if params[:note_id] && Task.where('tasks.id = ?', params[:note_id]).count > 0
      @note.parent_task = params[:note_id]
    end

    # TEST VERSION
    # @products = Product.sample_products(35, 20)

    @search_text = params[:product_search_text] || nil

    @product_selected = params[:product_selected] || nil

    @customer_text = params[:customer_search_text] || nil

    @selected_method = params[:selected_method] || 'Meeting'
    # production version
    if %w['Sales Executive'].include? session[:authority]
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
    redirect_to action: 'add_note'
  end

  # insert task
  # following Dropbox -> pages -> Activity
  def add_activity
    @customer_text = params[:customer_search_text] || nil

    @task = Task.new

    if params[:note_id] && Task.where('tasks.id = ?', params[:note_id]).count > 0
      @task.parent_task = params[:note_id]
      @wine_note_list = ProductNote.filter_task(params[:note_id])
    end

    @staff = Staff.active
    @function, @subjects, @methods, @function_role, @promotion, @portfolio \
      = function_search(params)

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
    relation_save(params, task)
    task_product_note(params, task, session[:user_id])
    flash[:success] = 'Task Saved!'
    redirect_to action: 'add_activity'
  end

  def history

  end

  # -----------private --------------------
  private

  def note_params
    params.require(:task).permit(:description, :subject_1, :function, :method,\
                                 :promotion_id, :portfolio_id, :start_date, \
                                 :end_date, :priority)
  end
end
