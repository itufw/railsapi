require 'models_filter.rb'
require 'sales_controller_helper.rb'
require 'dates_helper.rb'
require 'time_period_stats.rb'
require 'status_helper.rb'

class StatusController < ApplicationController

	before_action :confirm_logged_in

	include ModelsFilter
	include SalesControllerHelper
	include DatesHelper
	include TimePeriodStats
	include StatusHelper

	def pending
		@status_id, @status_name = get_id_and_name(params)
		staff_id, @staff = staff_filter(params)
		product_filtered_ids, @producer_country, @product_sub_type, @search_text = products(params, staff_id, @status_id)
		@per_page, @orders, @products, @last_order_date = orders(params, product_filtered_ids, staff_id, @status_id)
	end


	def summary_with_product
		get_id_and_name(params)
		@product_id = params[:product_id]
      	@product_name = params[:product_name]
      	@num_orders = params[:num_orders]
      	@qty = params[:qty]
      	@status_qty = params[:status_qty]
      	@total = params[:total]

      	staff_id = staff_filter(params)
      	orders(params, @product_id, staff_id)
      	@overall_stats = overall_stats_(params)

	end

	def overall_stats_(params)
		@selected_period, @period_types = define_period_types(params)
    	@result = overall_stats("Order.order_product_filter(%s).status_filter(%s)" % \
        [@product_id, @status_id], :sum_order_product_qty, @selected_period, nil)
    end

end
