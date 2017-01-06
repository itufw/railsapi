require 'models_filter.rb'
require 'product_variations.rb'

class ProductController < ApplicationController

	before_action :confirm_logged_in

	include ModelsFilter
  	include ProductVariations

  	def all
	    filer(params)
	    transform(params)

	    # check the number of queries - make it faster
	    @stock_h, @price_h, @pending_stock_h, products_transformed = \
	    all_products_transform(@transform_column, products)
	    
	    display_(params, products_transformed)
  	end

  	# Displays Overall Stats and Top Customers for Product
  	def summary

  	end

  	def filter(params)
  		@producer_country, @product_sub_type, products, @search_text = product_param_filter(params)
  	end

  	def transform(params)
  		@transform_column = params[:transform_column] || "product_id"
	    @checked_id, @checked_no_vintage, @checked_no_ws = checked_radio_button(@transform_column)
	end

	def display_(params, products)
		# sorting by every table col doesn't work
	    order_function, direction = sort_order(params, 'order_by_name', 'ASC')
	    
	    @per_page = params[:per_page] || Product.per_page
	    @products = products.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
	end


end