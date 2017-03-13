require 'models_filter.rb'
require 'display_helper.rb'
require 'product_variations.rb'
require 'order_helper.rb'

class OrderController < ApplicationController

    before_action :confirm_logged_in

    include ModelsFilter
    include DisplayHelper
    include ProductVariations
    include OrderHelper

    def all
     	@staff_nickname = params[:staff_nickname]
     	@start_date = params[:start_date]
     	@end_date = params[:end_date]
     	@staffs = Staff.active_sales_staff

     	#@can_update_bool = allow_to_update(session[:user_id])
     	@staff, @status, orders, @search_text, @order_id = order_controller_filter(params, "display_report")
     	@per_page, @orders = order_display_(params, orders)
    end

	def for_product
		@product_id = params[:product_id]
		@product_name = params[:product_name]
		@transform_column = params[:transform_column]

		# orders filtered by param
		@staff, @status, orders_filtered, @search_text, @order_id  = order_controller_filter(params, "product_rights")

		# get product_ids depending on the transform_column
		# if transform_column is product_no_vintage_id then we have a set of products
		# who have the same no_vintage_id
		@product_ids = get_products_after_transformation(@transform_column, @product_id).pluck("id") || [@product_id]
		# orders filtered by product
		orders = orders_filtered.order_product_filter(@product_ids)
		@per_page, @orders = order_display_(params, orders)
	end

	# Displays all details about an order
	# How do I get to this ? Click on a Order ID anywhere on the site
	def details
    	@order_id = params[:order_id]
      @per_page = params[:per_page] || Order.per_page
    	@order = Order.include_all.order_filter_(@order_id).paginate( per_page: @per_page, page: params[:page])

      @tasks = Task.active_tasks.order_tasks(@order_id).order_by_id('DESC')
	end

end
