require 'models_filter.rb'
require 'display_helper.rb'

class OrderController < ApplicationController

	before_action :confirm_logged_in

	include ModelsFilter
  	include DisplayHelper

	def all
    	@staff_nickname = params[:staff_nickname]
    	@start_date = params[:start_date]
    	@end_date = params[:end_date]
    	@staffs = Staff.active_sales_staff

    	@can_update_bool = allow_to_update(session[:user_id])

    	orders = filter(params)
    	display_(orders)
  	end

	# Displays all details about an order
	# How do I get to this ? Click on a Order ID anywhere on the site
	def details
    	@order_id = params[:order_id]
    	@order = Order.include_all.order_filter(@order_id)
	end

	def filter(params)
		@staff, @status, orders, @search_text, @order_id = order_param_filter(params, session[:user_id])
		return orders
	end

	def display_(orders)
		@per_page = params[:per_page] || Order.per_page
    	order_function, direction = sort_order(params, 'order_by_id', 'DESC')
		@orders = orders.include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
	end
end