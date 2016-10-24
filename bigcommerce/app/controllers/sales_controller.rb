require 'sales_controller_helper.rb'
require 'models_filter.rb'
require 'dates_helper.rb'
require 'display_helper.rb'
require 'stock_helper.rb'

class SalesController < ApplicationController

  before_action :confirm_logged_in

  include SalesControllerHelper
  include ModelsFilter
  include DatesHelper
  include DisplayHelper
  include StockHelper

  helper_method :check_id_in_map

  # Displays this week's and last week's total order sales
  # Also displays total order sales for this week divided by staff
  def sales_dashboard
    # Date selected by user , default is today's date
    date_given = return_date_given(params)

    @dates_this_week = this_week(date_given)
    @dates_last_week = last_week(@dates_this_week[0])

    sum_function, @checked_bottles, @checked_totals = order_sum_param(params[:sum_param])
    # returns a hashmap like { date => order_totals }
    @sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created, sum_function, nil)
    @sum_last_week = sum_orders(@dates_last_week[0], @dates_last_week[-1], :group_by_date_created, sum_function, nil)
    
    @dates_paired_this_week = make_daily_dates_map(@dates_this_week)
    @dates_paired_last_week = make_daily_dates_map(@dates_last_week)

    # returns a hashmap like { [staff_id, date] => order_totals }

    staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])
    
    @staff_sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created_and_staff_id, sum_function, staff_id)
    #@staff_nicknames = Staff.active_sales_staff.nickname.to_h
    @staff_sum_this_week
  end

  def sales_dashboard_detailed
    @end_date = return_end_date(return_date_given(params))
    if params[:num_period]
      @num_periods = params[:num_period].to_i
    else 
      @num_periods = 13
    end
    @selected_period, @period_types = define_period_types(params)

    # periods_from_end_date is defined in Dates Helper
    # returns an array of all dates - sorted
    # For example num_periods = 3, end_date = 5th oct and "monthly" as period_type returns
    # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
    # 6th Oct is the last date in the array and not 5th oct because
    # we want to calculate orders including 5th Oct, for that we need to give the next day
    dates = periods_from_end_date(@num_periods, @end_date, @selected_period)

    # order_sum_param takes into account what the user wants to calculate - Bottles or Order Totals
    # order_sum_param is defined in Sales Controller Helper
    # Sum function returns :sum_qty or :sum_total
    # These functions are defined in the Order model
    sum_function, @checked_bottles, @checked_totals, @param_val = order_sum_param(params[:sum_param])

    # sum_orders returns a hash like {date/week_num/month_num => sum} depending on the date_type
    # defined in Sales Controller Helper

    # date_type returns group_by_week_created or group_by_month_created
    date_function = period_date_functions(@selected_period)[2]
    @sums_by_periods = sum_orders(dates[0], dates[-1], date_function.to_sym, sum_function, nil)

    # returns a hash like {[start_date, end_date] => week_num/month_num}
    @dates_paired = pair_dates(dates, @selected_period)

    staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])
    @staff_sum_by_periods = sum_orders(dates[0], dates[-1], (date_function + "_and_staff_id").to_sym, sum_function, staff_id)
    
    @periods = (3..15).to_a
    @period_types = ["weekly", "monthly"]

  end

  # Displays all orders for selected customer
  # How do I get to this ? Click on Customer Name anywhere on the site
  # Displays all orders for that customer and a button to view stats
  def orders_and_stats_for_customer
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]

    @selected_period, @period_types = define_period_types(params)
    @orders = Order.include_customer_staff_status.customer_filter([@customer_id]).order_by_id.page(params[:page])
    @time_periods_name, all_stats, @sum_stats, @avg_stats, product_ids = stats_for_timeperiods("Order.customer_filter(%s).valid_order" % [[@customer_id]], :"", :sum_total, nil, @selected_period)
  end

  # Displays Stats for all the products the customer has ordered
  def top_products_for_customer
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
    @time_periods_name, @all_stats, @sum_stats, @avg_stats, product_ids = stats_for_timeperiods("Order.customer_filter(%s).valid_order" % [[@customer_id]], :group_by_product_id, :sum_order_product_qty, nil, nil)
    
    # returns a hash {id => name}
    @products_h = product_filter(product_ids)
  end

  # Displays all details about an order
  # How do I get to this ? Click on a Order ID anywhere on the site
  def order_details
    @order_id = params[:order_id]
    @order = Order.include_all.order_filter(@order_id)
  end

  # Displays overall stats for products(money gained) and all customers who bought that product
  def stats_and_top_customers_for_product
    @product_id = params[:product_id]
    @product_name = params[:product_name]

    @total_stock = params[:total_stock]
    @total_stock_no_ws = total_stock_product(@product_id, params[:total_stock])
    @selected_period, @period_types = define_period_types(params)

    @time_periods_name, @all_stats, @sum_stats, @avg_stats, customer_ids, @monthly_supply = stats_for_timeperiods("Order.product_filter(%s).valid_order" % @product_id, :group_by_customerid, :sum_order_product_qty, @total_stock_no_ws, @selected_period)

    @staffs = staff_dropdown

    results_val = customer_param_filter(params, 25)

    @staff = results_val[0]
    customers_filtered_ids = results_val[1].pluck("id")
    customers = Customer.filter_by_ids(customers_filtered_ids & customer_ids)
    customers_h = Hash.new
    customers.map {|c| customers_h[c.id] = [Customer.customer_name(c.actual_name, c.firstname, c.lastname), Staff.filter_by_id(c.staff_id).nickname]}
    @customers_h_sorted = customers_h.sort_by {|id, key| key[0]}
  end

  # How do I get to this ? - Click on the page that displays all products -
  # Look for your product - Then come to this page
  # Displays All the orders for the selected product, with the selected product qty
  # And displays a button to view stats
  def orders_for_product
    @product_id = params[:product_id]
    @product_name = params[:product_name]

    @staffs = Staff.active_sales_staff
    @statuses = Status.all

    @staff, @status, orders_filtered_by_param, @search_text = order_param_filter(params, session[:user_id])
    orders_filtered_by_product = Order.product_filter([@product_id]).pluck("id")
    order_ids = orders_filtered_by_param.pluck("id") & orders_filtered_by_product
    @orders = Order.include_customer_staff_status.order_filter_by_ids(order_ids).order_by_id.page(params[:page])
    @staff_nickname = params[:staff_nickname]
  end


  # How do we come to this page ? - We click on Order ID - then click on any one of the products
  # Displays Orders when selected customer ordered selected product and shows overall product stats
  # (money spent on that product by customer)
  # We also come here from top products for customer and from top customers for product
  def orders_and_stats_for_product_and_customer
    customer_id = params[:customer_id]
    @customer_name = params[:customer_name]

    product_id = params[:product_id]
    @product_name = params[:product_name]

    @selected_period, @period_types = define_period_types(params)
    @orders = Order.include_customer_staff_status.product_filter(product_id).customer_filter([customer_id]).order_by_id.page(params[:page])
    @time_periods_name, i, @sum_stats, @avg_stats = stats_for_timeperiods("Order.product_filter(%s).customer_filter(%s).valid_order" % [product_id, [customer_id]], "".to_sym, :sum_order_product_qty, nil, @selected_period)
  end

  # Gets orders and products for a selected status on two different pages
  # The same dataset is used, just displays in two formats
  # Thus the dataset can be filtered by 
  def orders_and_products_for_status
    @status_id = params[:status_id]
    @status_name = params[:status_name]

    if @status_id.nil?
      @status_id = 1
      @status_name = "Pending"
    end

    @all_statuses = Status.all
    @staffs = Staff.active_sales_staff
    @countries = ProducerCountry.all
    @sub_types = ProductSubType.all

    @producer_country, @product_sub_type, products, @search_text = product_param_filter(params)

    staff_id, @staff = staff_params_filter(params, session[:user_id])

    product_ids = products.pluck("id")

    # filter orders
    orders = Order.include_all.status_filter(@status_id).staff_filter(staff_id).product_filter(product_ids).order_by_id.page(params[:page])

    @orders = orders.page(params[:page])
    @products = products_for_status(@status_id, staff_id, product_ids)

  end

  # How do we come to this page ? - We go to 'Pending Orders page' - Click on a product name
  # Displays Overall Product Stats irrespective of Order's Status and 
  # Orders when selected product was ordered, and they currently have selected status 
  def orders_and_stats_for_product_and_status
      product_id = params[:product_id]
      @product_name = params[:product_name]

      status_id = params[:status_id]
      @status_name = params[:status_name]

      @num_orders = params[:num_orders]
      @qty = params[:qty]
      @status_qty = params[:status_qty]
      @total = params[:total] 
      @selected_period, @period_types = define_period_types(params)

      @time_periods_name, i, @sum_stats, @avg_stats = stats_for_timeperiods("Order.product_filter(%s).valid_order" % product_id, "".to_sym, :sum_order_product_qty, nil, @selected_period)

      @staffs = staff_dropdown

      staff_id, @staff = staff_params_filter(params, session[:user_id])
    
      @orders = Order.status_filter(status_id).staff_filter(staff_id).product_filter([product_id]).order_by_id.page(params[:page])
  end


end
