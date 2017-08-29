# filter products based on paramaters
require 'models_filter.rb'

# provide stats for no vintage products, no ws products
require 'product_variations.rb'

# to calculate overall stats and top customers
require 'time_period_stats.rb'

# for calendar period types for overall stats - weekly, monthly, quarterly
require 'dates_helper.rb'
require 'product_helper'
class ProductController < ApplicationController
  before_action :confirm_logged_in

  include ModelsFilter
  include ProductVariations
  include TimePeriodStats
  include DatesHelper
  include ProductHelper

  # Displays all products
  def all
    filtered_products = filter(params)
    transform(params)

    # check the number of queries - make it faster
    @stock_h, @price_h, @pending_stock_h, @name_h = \
      transform_product_data(@transform_column, filtered_products)
    display_all(params)
  end

  # Displays Overall Stats and Top Customers for Product
  def summary
    params[:direction] = params[:direction] || -1
    params[:order_col] = params[:order_col] || 'Last Quarter'

    params_for_one_product(params)
    transform(params)
    # total_stock is inventory in bigcommerce + pending stock
    get_total_stock(params)
    # WS + Retail + Pending stock
    @total_stock_no_ws = total_stock_no_ws(@transform_column, @product_id, @pending_stock, @total_stock)

    # either we want stats for a product_id
    # or for products based on a product_no_vintage_id
    # or based on a product_no_ws_id
    # this gives product_ids based on that transform_column
    product_ids = get_products_after_transformation(@transform_column, @product_id).pluck('id') || @product_id

    # form filter for top customers

    # i only need to check product rights on this page
    # So if product rights is 0, then restrict by staff
    # otherwise just do a normal param filter
    @staff, customers_filtered, @search_text, staff_id, @cust_style = \
      customer_filter(params, session[:user_id], 'product_rights')
    customers_filtered_ids = customers_filtered.pluck('id')
    # both overall stats and top customers change based on the customer filter

    # overall_stats has structure {time_period_name => [sum, average, supply]}
    @overall_stats = \
      overall(params, product_ids, customers_filtered_ids, @total_stock)

    # top customers
    top_customers(params, product_ids, customers_filtered_ids)

    # calculate the pending stock for each customer
    @customer_pendings, @customer_ids = \
      customer_pending_amount(product_ids, params, @customer_ids)
  end

  def overall(params, product_ids, customers_filtered_ids, total_stock)
    # period type for overall stats - monthly or weekly
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.order_product_filter(%s).customer_filter(%s).valid_order' % \
      [product_ids, customers_filtered_ids], :sum_order_product_qty, @selected_period, total_stock)
  end

  def top_customers(params, product_ids, customers_filtered_ids)
    # result_h has the form {time_period_name => {customer_id => stock_bought}}
    # and it is sorted according to order_col and direction
    @top_customers_timeperiod_h, @customer_ids, @time_periods, already_sorted = top_objects(\
      'Order.order_product_filter(%s).customer_filter(%s).valid_order' % \
        [product_ids, customers_filtered_ids], :group_by_customerid, :sum_order_product_qty,\
      params[:order_col], params[:direction]
    )
    if already_sorted
      @top_customers = get_id_activerecord_h(Customer.include_all.filter_by_ids(@customer_ids))
    else
      default_customer_sort_order(params)
      @top_customers = get_id_activerecord_h(Customer.include_all.filter_by_ids(@customer_ids).send(@order_function, @direction))
      @customer_ids = @top_customers.keys
    end
  end

  def params_for_one_product(params)
    @product_id = params[:product_id]
    @product_name = params[:product_name]
  end

  def filter(params)
    @producer_country, @product_sub_type, products, @search_text = product_filter(params)
    products
  end

  def transform(params)
    @transform_column = params[:transform_column] || 'product_no_vintage_id'
    @checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)
  end

  def display_all(params)
    @per_page = params[:per_page] || Product.per_page
    # order_function, direction = sort_order(params, 'order_by_name', 'ASC')
    sort_map = { '0' => @name_h, '1' => @price_h, '2' => @stock_h }
    needs_to_be_sorted_h = sort_map[params[:order_col]] || @name_h

    if params[:direction] == '-1'
      # hash that needs to be sorted
      sorted_hash = needs_to_be_sorted_h.sort_by { |_id, val| -val }.to_h
    else
      sorted_hash = needs_to_be_sorted_h.sort_by { |_id, val| val }.to_h
    end

    @product_ids = sorted_hash.keys.paginate(per_page: @per_page, page: params[:page])
  end

  def default_customer_sort_order(params)
    @order_function, @direction = sort_order(params, :order_by_name, 'ASC')
  end

  def get_id_activerecord_h(customers)
    id_activerecord_h = {}
    return id_activerecord_h if customers.blank?
    customers.map { |c| id_activerecord_h[c.id] = c }
    id_activerecord_h
  end

  def get_total_stock(params)
    @total_stock = params[:total_stock].to_i
    @pending_stock = params[:pending_stock].to_i
  end

  def incomplete_product
    @per_page = params[:per_page] || Product.per_page
    @products = Product.incompleted.paginate( per_page: @per_page, page: params[:page])
  end
end
