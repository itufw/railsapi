require 'time_period_stats.rb'
require 'product_variations.rb'
require 'models_filter.rb'
require 'dates_helper.rb'

class CustomerController < ApplicationController

	before_action :confirm_logged_in

	include TimePeriodStats
	include ProductVariations
	include ModelsFilter
  include DatesHelper


  # Orders and Overall Stats for Customer
  def summary
    get_id_and_name(params)
    # overall_stats has structure {time_period_name => [sum, average, supply]}
    @overall_stats = overall_stats_(params)
    orders(params)
  end

  def overall_stats_(params)
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats("Order.customer_filter(%s).valid_order" % \
        [[@customer_id]], :sum_total, @selected_period, nil)
  end

  def orders(params)
    order_function, direction = sort_order(params, :order_by_id, 'DESC')
    @per_page = params[:per_page] || Order.per_page
    @orders = Order.include_all.customer_filter([@customer_id]).send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
  end

  def get_id_and_name(params)
    @customer_id = params[:customer_id]
    @customer_name = params[:customer_name]
  end

	# Displays Stats for all the products the customer has ordered
	def top_products
  	get_id_and_name(params)

  	# filter products based on params
  	@producer_country, @product_sub_type, products, @search_text = product_param_filter(params)

  	# which view of products needs to be displayed - normal products, or no vintage products, etc.
		@transform_column = params[:transform_column] || "product_id"
  	@checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)

  	# Get top products
  	# To get top products, get all the orders for a customer, then get products of those orders
  	# based on the above param filters, filter products out
  	where_query = "Order.customer_filter(%s).valid_order.product_filter(%s)" % [[@customer_id], Product.all.pluck("id")]
		
		# hash has a structure {"time_period" => {product_id => stock}}
		# product_ids can be either product ids or even 
		# product no vintage ids
		# group_by can be group_by_product_id, group_by_product_no_vintage_id
		@top_products_timeperiod_h, @product_ids, @time_periods, sorted_bool = \
		top_objects(where_query, ('group_by_' + @transform_column).to_sym, :sum_order_product_qty, params[:order_col], params[:direction])
		
		@price_h, @product_name_h = top_products_transform(@transform_column, @product_ids)

    # Sort by name/price
    ####################################
    # PUT THIS IN A LIB
    unless sorted_bool
      sort_column_map = {"0" => @product_name_h, "1" => @price_h}
      # @name_h or @price_h are the structure {id => val}
      # sort the hash using the val, then get the product_ids in order using map
      hash_to_be_sorted = sort_column_map[params[:order_col]] || @product_name_h
      if params[:direction].to_i == 1
        @product_ids = hash_to_be_sorted.sort_by {|id, val| val}.map {|product| product[0]}
      else
        @product_ids = hash_to_be_sorted.sort_by {|id, val| -val}.map {|product| product[0]}
      end
    end
    ####################################
	end

end