require 'sales_controller_helper.rb'

class SalesController < ApplicationController

  before_action :confirm_logged_in

  include SalesControllerHelper

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
    @sum_this_week = sum_orders(@dates_this_week[0], @dates_this_week[-1])
    @sum_last_week = sum_orders(@dates_last_week[0], @dates_last_week[-1])

    # returns a hashmap like { [staff_id, date] => order_totals }
    @staff_sum_this_week = staff_sum_orders(@dates_this_week[0], @dates_this_week[-1])
    @staff_nicknames = Staff.active_sales_staff.nickname.to_h
  end


  # Displays all orders for selected customer
  # How do I get to this ? Click on Customer Name anywhere on the site
  # Displays all orders for that customer and a button to view stats
  def orders_for_selected_customer
    customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
    @orders = Order.include_customer_staff_status.customer_filter(customer_id).order_by_id.page(params[:page])
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
    product_id = params[:product_id]
    @product_name = params[:product_name]
    @orders = Order.include_customer_staff_status.filter_order_products(product_id, nil).order_by_id.page(params[:page])
  end

  # # Displays orders for a given status
  # def orders_for_selected_status

  # end

  # # Gets orders for a given status
  # # Groups that orders' products 
  # # Displays product name, total qty for that status, qty of that product, sum of order total
  # def products_for_selected_status

  # end

  #   # How do we come to this page ? - We click on Order ID - then click on any one of the products
  #   # Displays Orders when selected customer ordered selected product and shows overall product stats
  #   # (money spent on that product by customer)
  # def orders_for_selected_product_and_selected_customer
  #   customer_id = params[:customer_id]
  #   customer_name = params[:customer_name]

  #   product_id = params[:product_id]
  #   product_name = params[:product_name]
  
  #   orders = Order.include_customer_staff_status.filter_order_products(product_id, nil).customer_filter(customer_id).order_by_id
  #   stats_for_timeperiods("Order.filter_order_products(%s, nil).customer_filter(%s)" % [product_id, customer_id], "".to_sym, :sum_order_product_qty)
  # end

  # # How do we come to this page ? - We go to 'Pending Orders page' - Click on a product name
  # # Displays Overall Product Stats irrespective of Order's Status and 
  # # Orders when selected product was ordered, and they currently have selected status 
  # def orders_for_selected_product_and_selected_status
  #     product_id = params[:product_id]
  #     product_name = params[:product_name]

  #     status_id = params[:status_id]
  #     status_name = params[:status_name]

  #     num_orders = params[:num_orders]
  #     qty = params[:qty]
  #     status_qty = params[:status_qty]
  #     total = params[:total] 

  #     stats_for_timeperiods("Order.filter_order_products(%s, nil).valid_order" % product_id, "".to_sym, :sum_order_product_qty)

  #     @staffs = staff_dropdown

  #     param_filter_result = orders_param_filter(params, status_id, product_id, nil)

  #     @staff = param_filter_result[0]
  #     orders = param_filter_result[1] 
  #   end

  # # Displays Overall Stats for customer(Bottles ordered) and Stats for all the products the customer has ordered
  # def customer_stats
  #   customer_id = params[:customer_id]
  #   customer_name = params[:customer_name]

  #   product_ids = stats_for_timeperiods("Order.customer_filter(%s).valid_order" % customer_id, :group_by_product_id, :sum_order_product_qty)
  #   products = products_param_filter(nil, nil, nil, nil, product_ids)
  # end

  # # Displays overall stats for products(money gained) and all customers who bought that product
  # def product_stats
  #   product_id = params[:product_id]
  #   product_name = params[:product_name]

  #   customer_ids = stats_for_timeperiods("Order.filter_order_products(%s, nil).valid_order" % product_id, :group_by_customerid, :sum_order_product_qty)

  #   @staffs = staff_dropdown

  #   param_filter_result = customers_param_filter(params, nil, customer_ids)

  #   @staff = param_filter_result[0]
  #   customers = param_filter_result[1]
  # end

end
