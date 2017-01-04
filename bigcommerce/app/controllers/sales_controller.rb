require 'sales_controller_helper.rb'
require 'models_filter.rb'
require 'dates_helper.rb'
require 'display_helper.rb'
require 'product_variations.rb'

class SalesController < ApplicationController

  before_action :confirm_logged_in

  include SalesControllerHelper
  include ModelsFilter
  include DatesHelper
  include DisplayHelper
  include ProductVariations

  # Displays this week's and last week's total order sales
  # Also displays total order sales for this week divided by staff
  def sales_dashboard
    # Date selected by user , default is today's date
    date_given = return_date_given(params)

    @dates_this_week = this_week(date_given)
    @dates_last_week = last_week(@dates_this_week[0])

    sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])  

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
    sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param])
    @selected_period, @period_types = define_period_types(params)

    # periods_from_end_date is defined in Dates Helper
    # returns an array of all dates - sorted
    # For example num_periods = 3, end_date = 5th oct and "monthly" as period_type returns
    # [1st Aug, 1st Sep, 1st Oct, 6th Oct]
    # 6th Oct is the last date in the array and not 5th oct because
    # we want to calculate orders including 5th Oct, for that we need to give the next day
    dates = periods_from_end_date(@num_periods, @end_date, @selected_period)
     # returns a hash like {[start_date, end_date] => week_num/month_num}
    @dates_paired = pair_dates(dates, @selected_period)
    
    @periods = (3..15).to_a

    # order_sum_param takes into account what the user wants to calculate - Bottles or Order Totals
    # order_sum_param is defined in Sales Controller Helper
    # Sum function returns :sum_qty or :sum_total
    # These functions are defined in the Order model
    sum_function, @param_val, @sum_params = order_sum_param(params[:sum_param]) 

    # sum_orders returns a hash like {date/week_num/month_num => sum} depending on the date_type
    # defined in Sales Controller Helper

    # date_type returns group_by_week_created or group_by_month_created
    date_function = period_date_functions(@selected_period)[2]
    @sums_by_periods = sum_orders(dates[0], dates[-1], date_function.to_sym, sum_function, nil)
    
    staff_id, @staff_nicknames = display_reports_for_sales_dashboard(session[:user_id])
    @staff_sum_by_periods = sum_orders(dates[0], dates[-1], (date_function + "_and_staff_id").to_sym, sum_function, staff_id)

  end


  # Displays all orders for selected customer
  # How do I get to this ? Click on Customer Name anywhere on the site
  # Displays all orders for that customer and a button to view stats
  def orders_and_stats_for_customer
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
    @per_page = params[:per_page] || Order.per_page

    @selected_period, @period_types = define_period_types(params)

    @orders = Order.include_all.customer_filter([@customer_id]).order_by_id('DESC').paginate( per_page: @per_page, page: params[:page])
   
    @time_periods_name, all_stats, @sum_stats, @avg_stats, product_ids = \
    stats_for_timeperiods("Order.customer_filter(%s).valid_order" % [[@customer_id]], :"",\
     :sum_total, nil, @selected_period, nil)
  end

  # Displays Stats for all the products the customer has ordered
  def top_products_for_customer
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]

    # check the radio button in the view based on how you want to group products
    # group products by no_vintage_id or no_ws_id or don't group them at all
    @transform_column = params[:transform_column] || "id"
    @checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)

    # filter products
    @producer_country, @product_sub_type, products, @search_text = product_param_filter(params)

    where_query = "Order.customer_filter(%s).valid_order.product_filter(%s)" % [[@customer_id], products.pluck("id")]

    @time_periods_name, @all_stats, @sum_stats, @avg_stats, product_ids = \
    stats_for_timeperiods(where_query, :group_by_product_id, :sum_order_product_qty,\
     nil, nil, params[:sort_column_stats])
    
    if !product_ids.empty?
      # products_h is like {id => [name, price, retail_ws]}
      @products_h = top_products_filter(product_ids, params[:sort_column], params[:sort_column_stats])
    else
      @products_h = {}
    end
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
    #@total_stock = params[:total_stock]
    @transform_column = params[:transform_column]

    # total stock to display on page - pending + inventory + retail + ws
    @total_stock_no_ws = 0#total_stock_product(@product_id, params[:total_stock])

    # form filter for top customers
    @staff, customers_filtered, @search_text, staff_id, @cust_style = customer_param_filter(params, 25)

    if staff_id.nil?
      staff_id = "nil"
    end

    # period type for overall stats - monthly or weekly
    @selected_period, @period_types = define_period_types(params)

    # either we want stats for a product_id or for products based on a product_no_vintage_id
    # or based on a product_no_ws_id
    # this gives product_ids based on that transform_column
    product_ids = transform_product_ids(@transform_column, @product_id) || @product_id

    # Gives Overall Stats and Top Customers in arrays
    @time_periods_name, @all_stats, @sum_stats, @avg_stats, customer_ids, @monthly_supply = \
    stats_for_timeperiods("Order.product_filter(%s).valid_order.staff_filter(%s)" % [product_ids, staff_id],\
     :group_by_customerid, :sum_order_product_qty, @total_stock_no_ws, @selected_period, params[:sort_column_stats])

    # filter customers based on params and sort by column heading
    @customers_h = top_customer_filter(customer_ids & customers_filtered.pluck("id"),\
     params[:sort_column], params[:sort_column_stats])
  end

  # How do I get to this ? - Click on the page that displays all products -
  # Look for your product - Then come to this page
  # Displays All the orders for the selected product, with the selected product qty
  # And displays a button to view stats
  def orders_for_product
    @product_id = params[:product_id]
    @product_name = params[:product_name]
    @staff_nickname = params[:staff_nickname]
    @transform_column = params[:transform_column]

    @per_page = params[:per_page] || Order.per_page

    @staff, @status, orders_filtered_by_param, @search_textt, @order_id = \
    order_param_filter(params, session[:user_id])

    product_ids = transform_product_ids(@transform_column, @product_id) || [@product_id]

    orders_filtered_by_product = Order.product_filter(product_ids).pluck("id")

    order_ids = orders_filtered_by_param.pluck("id") & orders_filtered_by_product

    @orders = Order.include_all.order_filter_by_ids(order_ids).order_by_id('DESC').paginate( per_page: @per_page, page: params[:page])
  end


  # How do we come to this page ? - We click on Order ID - then click on any one of the products
  # Displays Orders when selected customer ordered selected product and shows overall product stats
  # (money spent on that product by customer)
  # We also come here from top products for customer and from top customers for product
  def orders_and_stats_for_product_and_customer
    customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
    @per_page = params[:per_page] || Order.per_page


    product_id = params[:product_id]
    @product_name = params[:product_name]

    @selected_period, @period_types = define_period_types(params)
    @orders = Order.include_all.product_filter(product_id).customer_filter([customer_id]).order_by_id('DESC').paginate( per_page: @per_page, page: params[:page])
    @time_periods_name, i, @sum_stats, @avg_stats = \
    stats_for_timeperiods("Order.product_filter(%s).customer_filter(%s).valid_order" % [product_id,\
     [customer_id]], "".to_sym, :sum_order_product_qty, nil, @selected_period, nil)
  end

  # Gets orders and products for a selected status on two different pages
  # The same dataset is used, just displays in two formats
  # Thus the dataset can be filtered by 
  def orders_and_products_for_status
    @status_id = params[:status_id]
    @status_name = params[:status_name]
    @per_page = params[:per_page] || Order.per_page


    if @status_id.nil?
      @status_id = 1
      @status_name = "Pending"
    end

    @producer_country, @product_sub_type, products, @search_text = product_param_filter(params)

    staff_id, @staff = staff_params_filter(params, session[:user_id])

    product_ids = products.pluck("id")

    # filter orders
    orders = Order.include_all.status_filter(@status_id).staff_filter(staff_id).product_filter(product_ids).order_by_id('DESC')

    @orders = orders.paginate( per_page: @per_page, page: params[:page])
    @products = products_for_status(@status_id, staff_id, product_ids)

  end

  # How do we come to this page ? - We go to 'Pending Orders page' - Click on a product name
  # Displays Overall Product Stats irrespective of Order's Status and 
  # Orders when selected product was ordered, and they currently have selected status 
  def orders_and_stats_for_product_and_status
      @product_id = params[:product_id]
      @product_name = params[:product_name]
      @per_page = params[:per_page] || Order.per_page


      @status_id = params[:status_id]
      @status_name = params[:status_name]

      @num_orders = params[:num_orders]
      @qty = params[:qty]
      @status_qty = params[:status_qty]
      @total = params[:total] 
      @selected_period, @period_types = define_period_types(params)

      @time_periods_name, i, @sum_stats, @avg_stats = \
      stats_for_timeperiods("Order.product_filter(%s).status_filter(%s)" % [@product_id, @status_id],\
       "".to_sym, :sum_order_product_qty, nil, @selected_period, nil)

      staff_id, @staff = staff_params_filter(params, session[:user_id])
    
      @orders = Order.include_all.status_filter(@status_id).staff_filter(staff_id).product_filter([@product_id]).order_by_id('DESC').paginate( per_page: @per_page, page: params[:page])
  end


end
