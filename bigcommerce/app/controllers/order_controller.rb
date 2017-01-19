require 'models_filter.rb'
require 'display_helper.rb'
require 'product_variations.rb'

class OrderController < ApplicationController

    before_action :confirm_logged_in

    include ModelsFilter
    include DisplayHelper
    include ProductVariations

    def all
     	@staff_nickname = params[:staff_nickname]
     	@start_date = params[:start_date]
     	@end_date = params[:end_date]
     	@staffs = Staff.active_sales_staff

     	#@can_update_bool = allow_to_update(session[:user_id])
     	orders = filter(params, "display_report")
     	display_(params, orders)
    end

	def for_product
		@product_id = params[:product_id]
		@product_name = params[:product_name]
		@transform_column = params[:transform_column]

		# orders filtered by param
		orders_filtered = filter(params, "product_rights")

		# get product_ids depending on the transform_column
		# if transform_column is product_no_vintage_id then we have a set of products
		# who have the same no_vintage_id
		@product_ids = get_products_after_transformation(@transform_column, @product_id).pluck("id") || [@product_id]
		# orders filtered by product
		orders = orders_filtered.order_product_filter(@product_ids)
		display_(params, orders)
	end

	# Displays all details about an order
	# How do I get to this ? Click on a Order ID anywhere on the site
	def details
    	@order_id = params[:order_id]
        @per_page = params[:per_page] || Order.per_page
    	@order = Order.include_all.order_filter_(@order_id).paginate( per_page: @per_page, page: params[:page])
	end

	def filter(params, rights_col)
		@staff, @status, orders, @search_text, @order_id = order_filter(params, session[:user_id], "product_rights")
		return orders
	end

	def display_(params, orders)
    	order_function, direction = sort_order(params, :order_by_id, 'DESC')
		@per_page = params[:per_page] || Order.per_page
		@orders = orders.include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
	end
end