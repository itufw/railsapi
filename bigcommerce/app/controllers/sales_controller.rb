require 'sales_controller_helper.rb'
require 'models_filter.rb'

class SalesController < ApplicationController

  before_action :confirm_logged_in

  include SalesControllerHelper
  include ModelsFilter

  helper_method :check_id_in_map

  # Displays this week's and last week's total order sales
  # Also displays total order sales for this week divided by staff
  def sales_dashboard
    # Date selected by user , default is today's date
    date_param = params[:selected_date]

    if date_param.blank?
      date_given = ""
    else
      date_given =  date_param[:selected_date].to_date
    end


    @dates_this_week = this_week(date_given)
    @dates_last_week = last_week(@dates_this_week[0])

    # returns a hashmap like { date => order_totals }
    @sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created)
    @sum_last_week = sum_orders(@dates_last_week[0], @dates_last_week[-1], :group_by_date_created)
    
    @dates_paired_this_week = make_daily_dates_map(@dates_this_week)
    @dates_paired_last_week = make_daily_dates_map(@dates_last_week)

    # returns a hashmap like { [staff_id, date] => order_totals }
    @staff_sum_this_week = staff_sum_orders(@dates_this_week[0], @dates_this_week[-1], :group_by_date_created_and_staff_id)
    @staff_nicknames = Staff.active_sales_staff.nickname.to_h
  end

  def sales_dashboard_detailed
    weekly_dates = periods_from_end_date(13, Date.today)
    @sums_by_periods = sum_orders(weekly_dates[0], weekly_dates[-1], :group_by_week_created)
    @dates_paired = pair_dates(weekly_dates)

    @staff_sum_by_periods = staff_sum_orders(weekly_dates[0], weekly_dates[-1], :group_by_week_created_and_staff_id)
    @staff_nicknames = Staff.active_sales_staff.nickname.to_h


  end


  # Displays all orders for selected customer
  # How do I get to this ? Click on Customer Name anywhere on the site
  # Displays all orders for that customer and a button to view stats
  def orders_for_selected_customer
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
    @orders = Order.include_customer_staff_status.customer_filter([@customer_id]).order_by_id.page(params[:page])
  end

  # Displays all details about an order
  # How do I get to this ? Click on a Orde ID anywhere on the site
  def order_details
      @order_id = params[:order_id]
      @order = Order.include_all.order_filter(@order_id)
  end

  # How do I get to this ? - Click on the page that displays all products -
  # Look for your product - Then come to this page
  # Displays All the orders for the selected product, with the selected product qty
  # And displays a button to view stats
  def orders_for_selected_product
    @product_id = params[:product_id]
    @product_name = params[:product_name]
    @orders = Order.include_customer_staff_status.product_filter(@product_ids).order_by_id.page(params[:page])
  end

  # Gets orders and products for a selected status on two different pages
  # The same dataset is used, just displays in two formats
  # Thus the dataset can be filtered by 
  def orders_and_products_for_selected_status
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

    results_val_product = product_param_filter(params)
    @producer_country = results_val_product[0]
    @product_sub_type = results_val_product[1]
    @search_text = results_val_product[3]

    results_val_staff = staff_params_filter(params)
    staff_id = results_val_staff[0]
    @staff = results_val_staff[1]

    product_ids = results_val_product[2].pluck("id")

    # filter orders
    orders = Order.include_all.status_filter(@status_id).staff_filter(staff_id).product_filter(product_ids).order_by_id.page(params[:page])

    @orders = orders.page(params[:page])
    @products = products_for_status(@status_id, staff_id, product_ids)

  end


    # # How do we come to this page ? - We go to 'Pending Orders page' - Click on a product name
  # # Displays Overall Product Stats irrespective of Order's Status and 
  # # Orders when selected product was ordered, and they currently have selected status 
  def orders_and_stats_for_selected_product_and_selected_status
      product_id = params[:product_id]
      @product_name = params[:product_name]

      status_id = params[:status_id]
      @status_name = params[:status_name]

      @num_orders = params[:num_orders]
      @qty = params[:qty]
      @status_qty = params[:status_qty]
      @total = params[:total] 

      results_val = stats_for_timeperiods("Order.product_filter(%s).valid_order" % product_id, "".to_sym, :sum_order_product_qty)
      @time_periods_name = results_val[0]
      @sum_stats = results_val[2]
      @avg_stats = results_val[3]

      @staffs = staff_dropdown

      results_val_staff = staff_params_filter(params)
      staff_id = results_val_staff[0]
      @staff = results_val_staff[1]

      @orders = Order.status_filter(status_id).staff_filter(staff_id).product_filter([product_id]).order_by_id.page(params[:page])
    end

    # How do we come to this page ? - We click on Order ID - then click on any one of the products
    # Displays Orders when selected customer ordered selected product and shows overall product stats
    # (money spent on that product by customer)
  def orders_and_stats_for_selected_product_and_selected_customer
    customer_id = params[:customer_id]
    @customer_name = params[:customer_name]

    product_id = params[:product_id]
    @product_name = params[:product_name]
  
    @orders = Order.include_customer_staff_status.product_filter(product_id).customer_filter([customer_id]).order_by_id.page(params[:page])
    return_val = stats_for_timeperiods("Order.product_filter(%s).customer_filter(%s)" % [product_id, [customer_id]], "".to_sym, :sum_order_product_qty)
    @time_periods_name = return_val[0]
    @sum_stats = return_val[2]
    @avg_stats = return_val[3]
  end

  # # Displays Overall Stats for customer(Bottles ordered) and Stats for all the products the customer has ordered
  def customer_stats
    customer_id = params[:customer_id]
    @customer_name = params[:customer_name]

    results_val = stats_for_timeperiods("Order.customer_filter(%s).valid_order" % [[customer_id]], :group_by_product_id, :sum_order_product_qty)
    @time_periods_name = results_val[0]
    @all_stats = results_val[1]
    @sum_stats = results_val[2]
    @avg_stats = results_val[3]
    product_ids = results_val[4]

    # returns a hash {id => name}
    @products_h = product_filter(product_ids)
  end

  # Displays overall stats for products(money gained) and all customers who bought that product
  def product_stats
    @product_id = params[:product_id]
    @product_name = params[:product_name]

    results_val = stats_for_timeperiods("Order.product_filter(%s).valid_order" % @product_id, :group_by_customerid, :sum_order_product_qty)
    @time_periods_name = results_val[0]
    @all_stats = results_val[1]
    @sum_stats = results_val[2]
    @avg_stats = results_val[3]
    customer_ids = results_val[4]

    @staffs = staff_dropdown

    results_val = customer_param_filter(params)

    @staff = results_val[0]
    customers_filtered_ids = results_val[1].pluck("id")
    @customers_h = Customer.filter_by_ids(customers_filtered_ids & customer_ids)
  end

end
