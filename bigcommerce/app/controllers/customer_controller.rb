require 'time_period_stats.rb'
require 'product_variations.rb'
require 'models_filter.rb'

class CustomerController < ApplicationController

	before_action :confirm_logged_in

	include TimePeriodStats
	include ProductVariations
	include ModelsFilter

	# Displays Stats for all the products the customer has ordered
  	def top_products
    	@customer_id = params[:customer_id]
    	@customer_name = params[:customer_name]

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
  		@top_products_timeperiod_h, @product_ids, @time_periods = \
  		top_objects(where_query, ('group_by_' + @transform_column).to_sym, :sum_order_product_qty, params[:sort_column_stats])
  		

  		@price_h, @product_name_h = transform_products(@transform_column, @product_ids)
  	end

end