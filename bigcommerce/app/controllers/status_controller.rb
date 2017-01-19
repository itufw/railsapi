require 'models_filter.rb'
require 'sales_controller_helper.rb'
require 'dates_helper.rb'
require 'time_period_stats.rb'

class StatusController < ApplicationController

	before_action :confirm_logged_in

	include ModelsFilter
	include SalesControllerHelper
	include DatesHelper
	include TimePeriodStats

	def pending
		get_id_and_name(params)
		staff_id = staff_filter(params)
		product_filtered_ids = products(params, staff_id)
		orders(params, product_filtered_ids, staff_id)
	end

	def orders(params, product_ids, staff_id)
		orders = Order.include_all.status_filter(@status_id).staff_filter(staff_id).product_filter(product_ids)

		order_function, direction = sort_order(params, :order_by_id, 'DESC')
		@per_page = params[:per_page] || Order.per_page
		@orders = orders.include_all.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
	end

	def products(params, staff_id)
		@producer_country, @product_sub_type, products, @search_text = product_filter(params)
		product_ids = products.pluck("id")
		@products = products_for_status(@status_id, staff_id, product_ids)
		return product_ids
	end

	def staff_filter(params)
		staff_id, @staff = staff_params_filter(params)
		return staff_id
	end

	def get_id_and_name(params)
		@status_id = params[:status_id]
    	@status_name = params[:status_name]
    	if @status_id.nil?
      		@status_id = 1
      		@status_name = "Pending"
    	end
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
