require 'time_period_stats.rb'
require 'product_variations.rb'
require 'models_filter.rb'
require 'dates_helper.rb'
require 'customer_helper.rb'
require 'accounts_helper.rb'

class CustomerController < ApplicationController
  before_action :confirm_logged_in

  include TimePeriodStats
  include ProductVariations
  include ModelsFilter
  include DatesHelper
  include CustomerHelper
  include AccountsHelper

  # NEW CUSTOMER PAGE
  def contact
    @customer = Customer.find('1807')
    @overall_stats = overall_stats_(params)
    @orders, @per_page = latest_orders(params, Order.customer_filter([@customer.id]))
    @activity = Task.joins(:staff).customer_tasks(@customer.id).expired?
    @subjects = TaskSubject.filter_by_ids(@activity.map(&:subject_1).compact)

  end

  def all
    @staffs = Staff.active_sales_staff.order_by_order
    customers = filter(params, 'display_report')
    display_(params, customers)
  end

  def new_customers
    @staffs = Staff.active_sales_staff.order_by_order
    customers = filter(params, 'display_report')

    start_date = params[:start_date] || { start_date: (Date.today - 14.days).to_date.to_s }
    @start_date = return_end_date_invoices(start_date)
    @end_date = return_end_date_invoices(params[:end_date])
    # hepler -> customer_helper
    @per_page, @customers = get_new_customers(params, customers, @start_date, @end_date)
  end

  def incomplete_customers
    customers_filtered = filter(params, 'display_report')
    display_(params, customers_filtered.incomplete)
    render 'all'
  end

  # Orders and Overall Stats for Customer
  def summary
    get_id_and_name(params)
    # overall_stats has structure {time_period_name => [sum, average, supply]}
    @overall_stats = overall_stats_(params)
    display_orders(params, Order.customer_filter([@customer_id]))

    # task section
    @activity = Task.joins(:staff).customer_tasks(@customer_id).expired?.order_by_id('DESC')
    @subjects = TaskSubject.filter_by_ids(@activity.map(&:subject_1).compact)
    # -------------------
    # multiple contact people
    @customer = Customer.find(@customer_id)
    @contacts = @customer.cust_contacts
    # calculate the invoice table based
    # function located in helper -> accounts_helper
    @amount_due = get_invoice_table(@customer_id, 'monthly', Date.today)
  end

  def summary_with_product
    get_id_and_name(params)
    @product_id = params[:product_id]
    @product_name = params[:product_name]
    @transform_column = params[:transform_column] || 'product_id'

    # either we want stats for a product_id or for products based on a product_no_vintage_id
    # or based on a product_no_ws_id
    # this gives product_ids based on that transform_column
    @product_ids = get_products_after_transformation(@transform_column, @product_id).pluck('id') || [@product_id]

    # overall_stats has structure {time_period_name => [sum, average, supply]}
    @overall_stats = overall_stats_with_product(params, @product_ids)
    display_orders(params, Order.customer_filter([@customer_id]).product_filter(@product_ids))

    products = Product.send('group_by_' + @transform_column)
    total_stock = products.sum(:inventory)
    @pending_stock = OrderProduct.product_filter(products.pluck('id')).product_pending_stock('group_by_' + @transform_column)[@product_id]
    @total_stock = total_stock[@product_id.to_i].to_i + @pending_stock.to_i
  end

  def overall_stats_(params)
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.customer_filter(%s).valid_order' % \
        [[@customer_id]], :sum_total, @selected_period, nil)
  end

  def overall_stats_with_product(params, product_ids)
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.customer_filter(%s).order_product_filter(%s).valid_order' % \
        [[@customer_id], product_ids], :sum_order_product_qty, @selected_period, nil)
  end

  def display_orders(params, orders)
    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    @per_page = params[:per_page] || Order.per_page
    @orders = orders.include_all.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end

  def get_id_and_name(params)
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
  end

  def filter(params, rights_col)
    @staff, customers, @search_text, staff_id, @cust_style = customer_filter(params, session[:user_id], rights_col)
    customers
  end

  def display_(params, customers)
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @per_page = params[:per_page] || Customer.per_page
    @customers = customers.include_all.send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end

  def edit
    get_id_and_name(params)
    # params[:customer][:id] is used since update is a post request
    # once you update using post request,
    # then want to update again, we need to use params[:customer][:id]
    @customer = Customer.include_all.filter_by_id(@customer_id || params[:customer][:id])
  end

  def update
    @customer = Customer.filter_by_id(params[:customer][:id])
    if @customer.update_attributes(customer_params)
      flash[:success] = 'Successfully Changed.'
      redirect_to action: 'summary',\
                  customer_id: params[:customer][:id],\
                  customer_name: Customer.customer_name(@customer.actual_name, @customer.firstname, @customer.lastname)
    else
      flash[:error] = 'Unsuccessful.'
      render 'edit'
    end
  end

  def update_staff
    customer_id = params[:customer_id]
    staff_id = params[:staff_id]

    Customer.staff_change(staff_id, customer_id)
    # render html: "#{customer_id}, #{staff_id}".html_safe
    flash[:success] = 'Staff Successfully Changed.'
    redirect_to request.referrer
  end

  def update_order_staff
    order_id = params[:order_id]
    staff_id = params[:staff_id]

    order = Order.find(order_id)
    order.staff_id = staff_id
    order.save

    # render html: "#{customer_id}, #{staff_id}".html_safe
    flash[:success] = 'Staff Successfully Changed.'
    redirect_to request.referrer
  end

  # Displays Stats for all the products the customer has ordered
  def top_products
    get_id_and_name(params)

    # filter products based on params
    @producer_country, @product_sub_type, products, @search_text = product_filter(params)

    # which view of products needs to be displayed - normal products, or no vintage products, etc.
    @transform_column = params[:transform_column] || 'product_no_vintage_id'
    @checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)

    # Get top products
    # To get top products, get all the orders for a customer, then get products of those orders
    # based on the above param filters, filter products out
    where_query = 'OrderProduct.valid_orders.order_customer_filter(%s).product_filter(%s)' % [[@customer_id], Product.all.pluck('id')]

    # default sorting with name
    order_col = params[:order_col] || '0'
    order_direction = params[:direction] || '1'

    # hash has a structure {"time_period" => {product_id => stock}}
    # product_ids can be either product ids or even
    # product no vintage ids
    # group_by can be group_by_product_id, group_by_product_no_vintage_id
    @top_products_timeperiod_h, @product_ids, @time_periods, sorted_bool = \
      top_objects(where_query, ('group_by_' + @transform_column).to_sym, :sum_qty, order_col, order_direction)
    @price_h, @product_name_h = get_data_after_transformation(@transform_column, @product_ids)
    # Sort by name/price
    ####################################
    # PUT THIS IN A LIB
    unless sorted_bool
      sort_column_map = { '0' => @product_name_h, '1' => @price_h }
      # @name_h or @price_h are the structure {id => val}
      # sort the hash using the val, then get the product_ids in order using map
      hash_to_be_sorted = sort_column_map[order_col] || @product_name_h
      sorted_hash = hash_to_be_sorted.sort_by { |_id, val| val }

      if order_direction.to_i == 1
        @product_ids = sorted_hash.map { |product| product[0] }
      else
        @product_ids = sorted_hash.reverse.map { |product| product[0] }
      end
    end
    ####################################
  end

  private

  def customer_params
    params.require(:customer).permit(:firstname, :lastname, :actual_name, :staff_id, :cust_style_id,\
                                     :cust_group_id)
  end
end
