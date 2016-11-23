require 'models_filter.rb'
require 'display_helper.rb'

class ModelsController < ApplicationController

  before_action :confirm_logged_in

  include ModelsFilter
  include DisplayHelper
  
  def orders
    @staff_nickname = params[:staff_nickname]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @staffs = Staff.active_sales_staff

    @can_update_bool = allow_to_update(session[:user_id])

    @per_page = params[:per_page] || Order.per_page
    order_function, direction = sort_order(params, 'order_by_id', 'DESC')

    @staff, @status, orders, @search_text, @order_id = order_param_filter(params, session[:user_id])
    @orders = orders.include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])

  end

  def customers
    @can_update_bool = allow_to_update(session[:user_id])
    @per_page = params[:per_page] || Customer.per_page
    @staffs = Staff.active_sales_staff

    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @staff, customers, @search_text, staff_id, @cust_style = customer_param_filter(params, session[:user_id])

    @customers = customers.include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])

  end

  def edit_customer
    @customer = Customer.include_all.filter_by_id(params[:customer_id] || params[:customer][:id])
    @customer_name = Customer.customer_name(@customer.actual_name, @customer.firstname, @customer.lastname)
  end

  def update_customer
    @customer = Customer.filter_by_id(params[:customer][:id])
    if @customer.update_attributes(customer_params)
      flash[:success] = "Successfully Changed." 
      redirect_to controller: 'sales', action: 'orders_and_stats_for_customer',\
       customer_id: params[:customer][:id],\
       customer_name: Customer.customer_name(@customer.actual_name, @customer.firstname, @customer.lastname)
    else
      flash[:error] = "Unsuccessful."
      render 'edit_customer'
    end

  end

  def incomplete_customers
    @can_update_bool = allow_to_update(session[:user_id])
    @per_page = params[:per_page] || Customer.per_page

    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @staff, customers, @search_text, staff_id, @cust_style = customer_param_filter(params, session[:user_id])
    @customers = customers.incomplete.include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
  end

  def products

    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @per_page = params[:per_page] || Product.per_page

    @producer_country, @product_sub_type, products, @search_text = product_param_filter(params)

    @pending_stock_h = Product.pending_stock(products.pluck("id"))
    @products = products.paginate( per_page: @per_page, page: params[:page]).send(order_function, direction)

  end

  def update_staff
    customer_id = params[:customer_id]
    staff_id = params[:staff_id]

    Customer.staff_change(staff_id, customer_id)

    #render html: "#{customer_id}, #{staff_id}".html_safe
    flash[:success] = "Staff Successfully Changed."
    redirect_to request.referrer

  end

  private

  def customer_params
    params.require(:customer).permit(:firstname, :lastname, :actual_name, :staff_id, :cust_style_id,\
      :cust_group_id)
  end

end
