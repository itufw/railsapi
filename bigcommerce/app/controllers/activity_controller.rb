require 'activity_helper.rb'

# The replacement of task controller
class ActivityController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true
  autocomplete :product, :ws, full: true
  autocomplete :product, :retail, column_name: 'name', full: true, scopes: [:retail_products], extra_data: [:calculated_price, :inventory]
  autocomplete :product_no_ws, :name, full: true, extra_data: [:product_no_vintage_id]
  autocomplete :product_no_vintage, :name, full: true
  autocomplete :customer, :actual_name, full: true, extra_data: [:address]
  autocomplete :customer, :retail, column_name: 'actual_name', full: true, scopes: [:retail_customer]
  autocomplete :customer_lead, :actual_name, full: true, scopes: :not_customer
  autocomplete :contact, :name, display_value: :display_position, scopes: :has_role
  autocomplete :staff, :nickname, extra_data: [:nickname]
  autocomplete :sale_rate_term, :name, full: true
  autocomplete :producer, :name, full: true

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
      if params[:task_type]
        @completed_parent = params[:task_type]
        @note.description = "Complete: \n" + @parent.description
      end
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

    @product_selected = params[:product_selected] || nil

    @customer_id = params[:customer_id]
    @lead_id = params[:lead_id]
  end

  def save_note
    note = note_save(note_params, session[:user_id], params[:parent_task])
    # complted: task_control_icon -> add_note -> save_note
    Task.find(note.parent_task).complete_task(session[:user_id]) if note.parent_task && params[:completed_parent] == 'completed'

    product_note_save(params, session[:user_id], note.id)
    customer_id, role = relation_save(params, note)
    flash[:success] = 'Note Saved!'
    if 'new_task' == params[:button]
      redirect_to action: 'add_activity', note_id: note.id
      return
    end
    if role=="customer"
      redirect_to controller: 'customer', action: 'summary', customer_id: customer_id, customer_name: Customer.find(customer_id).actual_name
    else
      redirect_to controller: 'lead', action: 'summary', lead_id: customer_id
    end
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

    @customer_id = params[:customer_id]

    @lead_id = params[:lead_id]
  end

  def save_task
    task = note_save(note_params, session[:user_id])
    customer_id, role = relation_save(params, task)
    task_product_note(params, task, session[:user_id])
    flash[:success] = 'Task Saved!'
    if role=="customer"
      redirect_to controller: 'customer', action: 'summary', customer_id: customer_id, customer_name: Customer.find(customer_id).actual_name
    else
      redirect_to controller: 'lead', action: 'summary', lead_id: customer_id
    end
  end

  def selected_customer
    customer = Customer.find(params[:customer_id])
    @invoices = customer.xero_invoices.has_amount_due
    @cust_contacts = customer.cust_contacts
    respond_to do |format|
      format.js
    end
  end

  def activity_edit
    begin
      @activity = Task.find(params[:note_id])
      @function, @subjects = function_search(params)
      @staff = Staff.active
    rescue
      flash[:error] = 'Error'
      redirect_to :back
    end
  end

  def update
    activity = note_update(note_params, session[:staff_id], params[:activity_id])
    customer_id, destination = relation_save(params, activity)

    task_product_note(params, activity, session[:user_id])

    if params['button'] == 'complete'
      redirect_to controller: 'activity', action: 'add_note', note_id: activity.id, task_type: 'completed'
    elsif destination == 'customer'
      redirect_to controller: 'customer', action: 'summary', customer_id: customer_id, customer_name: Customer.find(customer_id).actual_name
      return
    else
      redirect_to controller: 'lead', action: 'summary', lead_id: customer_id
    end
  end

  # select only beers for autocomplete list
  def autocomplete_beer_name
    products = Product.search_for(params[:term]).where('product_sub_type_id = 59 and retail_ws = "R"').order('name ASC').all
    render :json => products.map { |product| {:id => product.id, :label => product.name,
      :value => product.name, :price => product.calculated_price.round(4)*1.1, 
      :inventory => product.inventory}}
  end

  # select only beers for autocomplete list
  def autocomplete_beer_ws
    products = Product.search_for(params[:term]).where('product_sub_type_id = 59 and retail_ws = "WS"').order('name ASC').all
    render :json => products.map { |product| {:id => product.id, :label => product.name,
      :value => product.name, :price => product.calculated_price.round(4), :inventory => product.inventory}}
  end

  # select only retail products for autocomplete list
  def autocomplete_product_name
    products = Product.search_for(params[:term]).where('inventory > 0').order('name_no_vintage ASC, vintage DESC').all
    render :json => products.map { |product| {:id => product.id, :label => product.name,
      :value => product.name, :price => product.calculated_price.round(4), :inventory => product.inventory}}
  end

  # select only whole sale products for autocomplete list
  def autocomplete_product_ws
    #products = Product.search_for(params[:term]).where("inventory > 0 AND name LIKE '%WS' AND current=1").order('name_no_vintage ASC, vintage DESC').all
    products = Product.search_for(params[:term]).where("(name LIKE '%WS' OR name LIKE '%VC') AND current=1").order('name_no_vintage ASC, vintage DESC').all
    render :json => products.map { |product| {:id => product.id, :label => product.name,
      :value => product.name, :price => (product.calculated_price * (1.29)).round(4),
      :inventory => product.inventory, :monthly_supply => product.monthly_supply}}
  end

  # add allocated products to the autocomplete list
  def with_allocated products
    product_hash = {}
    allocated_products = OrderProduct.joins(:order).select('product_id, SUM(order_products.qty) as qty').where('orders.status_id': 1).group('product_id')

    products.each do |p|
      # Separate Perth Stock
      # next if p.product_name.include?'Perth'

      # initialise the hash
      product = (product_hash[p.id].nil?) ? {inventory: 0} : product_hash[p.id]
      product[:order_total] = 0 unless product[:order_total].to_i!=0


      product[:name] = p.name_no_winery unless p.name_no_winery.nil?
      product[:inventory] += p.inventory
      product[:case_size] = p.case_size
      product[:order_total] = (p.order_1.to_i + p.order_2.to_f*0.1).to_f unless p.order_1.to_i==0

      allocated = allocated_products.detect{|x| x.product_id==p.product_id}
      product[:allocated] = 0 if !allocated.nil? && product[:allocated].nil?
      product[:allocated] += allocated.qty unless allocated.nil?
      product[:status] = p.product_status.name unless p.product_status.nil?

      if (p.retail_ws=='R')&&(!p.product_name.include?'DM')
        product[:rrp] = (p.price * 1.1).round(2)
      elsif p.product_name.include?'WS'
        product = product.merge({ws_id: p.product_id, luc: (p.price * 1.29).round(2),
          current: p.current})

        product[:term_1] = p.sale_term_1 unless p.sale_term_1.nil? || p.sale_term_1.zero?
        product[:monthly_supply] = p.monthly_supply.round(0) unless p.monthly_supply.nil? || p.monthly_supply.round(0).zero?
      end

      product_hash[p.id] = product
    end
  end

  # -----------private --------------------
  private

  def note_params
    params.require(:task).permit(:description, :subject_1, :function, :method,\
                                 :promotion_id, :portfolio_id, :start_date, \
                                 :end_date, :priority)
  end
end
