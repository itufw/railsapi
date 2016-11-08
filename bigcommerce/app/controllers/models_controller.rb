require 'models_filter.rb'
require 'display_helper.rb'

class ModelsController < ApplicationController

  before_action :confirm_logged_in

  include ModelsFilter
  include DisplayHelper
  
  def orders
    @staffs = Staff.active_sales_staff

    @staff_nickname = params[:staff_nickname]
    @start_date = params[:start_date]
    @end_date = params[:end_date]

    @can_update_bool = allow_to_update(session[:user_id])
    @statuses = Status.all

    @per_page = params[:per_page] || Order.per_page


    @staff, @status, orders, @search_text, @order_id = order_param_filter(params, session[:user_id])
    @orders = orders.include_all.order_by_id.paginate( per_page: @per_page, page: params[:page])

  end

  def customers
    @staffs = Staff.active_sales_staff
    @can_update_bool = allow_to_update(session[:user_id])
    @per_page = params[:per_page] || Customer.per_page

    @staff, customers, @search_text = customer_param_filter(params, session[:user_id])
    @customers = customers.include_all.order_by_name.paginate( per_page: @per_page, page: params[:page])

  end

  def products

    @countries = ProducerCountry.all
    @sub_types = ProductSubType.all
    results_val = product_param_filter(params)

    @per_page = params[:per_page] || Product.per_page

    @producer_country = results_val[0]
    @product_sub_type = results_val[1]
    products = results_val[2]
    @search_text = results_val[3]

    @pending_stock_h = Product.pending_stock(products.pluck("id"))
    @products = Product.all.order_by_name.paginate( per_page: @per_page, page: params[:page])

  end

  def update_staff
    customer_id = params[:customer_id]
    staff_id = params[:staff_id]

    Customer.staff_change(staff_id, customer_id)

    #render html: "#{customer_id}, #{staff_id}".html_safe
    flash[:success] = "Staff Successfully Changed."
    redirect_to request.referrer

  end

end
