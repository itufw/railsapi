require 'models_filter.rb'

class ModelsController < ApplicationController

  before_action :confirm_logged_in

  include ModelsFilter
  
  def orders

    @staffs = Staff.active_sales_staff
    @statuses = Status.all

    @staff, @status, orders, @search_text = order_param_filter(params, session[:user_id])
    @orders = orders.order_by_id.page(params[:page])

    # @staff = results_val[0]
    # @status = results_val[1]
    # @orders = results_val[2].order_by_id.page(params[:page])
    # @search_text = results_val[3]
    @start_date = params[:start_date]
    @end_date = params[:end_date]

    @staff_nickname = params[:staff_nickname]
  end

  def customers
    @staffs = Staff.active_sales_staff

    results_val = customer_param_filter(params)

    @staff = results_val[0]
    @customers = results_val[1].order_by_name.page(params[:page])
    @search_text = results_val[2]

  end

  def products

    @countries = ProducerCountry.all
    @sub_types = ProductSubType.all

    results_val = product_param_filter(params)

    @producer_country = results_val[0]
    @product_sub_type = results_val[1]
    @products = results_val[2].order_by_name.page(params[:page])
    @search_text = results_val[3]

    @pending_stock_h = Product.pending_stock(@products.pluck("id"))

  end

end
