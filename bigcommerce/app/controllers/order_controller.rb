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
     	@staffs = Staff.active_sales_staff.order_by_order

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
    if params[:selected_orders].nil?
      @order_id = params[:order_id]
    elsif params[:selected_orders].blank?
      redirect_to controller: 'order', action: 'all'
      return
    else
      @order_id = params[:selected_orders].delete_at(0)
      @selected_orders = params[:selected_orders]
    end

      @per_page = params[:per_page] || Order.per_page
    	@order = Order.include_all.order_filter_(@order_id).paginate( per_page: @per_page, page: params[:page])

      @tasks = Task.active_tasks.order_tasks(@order_id).order_by_id('DESC')
	end

  def order_update
    @order = Order.find(params[:order_id])
  end

  def fetch_order_detail
    @order_id = params[:order_id]
    respond_to do |format|
      format.js
    end
  end

  def generate_pod
    order = Order.find(params[:order_id])
    item = FastwayConsignmentItem.filter_order(params[:order_id]).first
    return if item.nil?

    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
          :template => 'pdf/proof_of_delivery.pdf',
          :locals => {order: order, item: item }
          )
      )
      send_data pdf, filename: "pod-#{order.id}.pdf", type: :pdf
  end

  def create_order
    @order = Order.new
    @order.discount_rate = 0
    @order.shipping_cost = 0
  end

  def save_order
    # Order Helper -> Move to Lib later
    order_creation(order_params, products_params)
    redirect_to action: 'all'
  end

  def generate_invoice
    order = Order.find(params[:order_id])
    customer = Customer.find(order.customer_id)
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
          :template => 'pdf/order_invoice.pdf',
          :locals => {order: order, customer: customer}
          )
      )
      send_data pdf, filename: "#{order.id}.pdf", type: :pdf
  end

  def update_order
    # Wrap this in a lib later
    wet = TaxPercentage.wet_percentage * 0.01
    handling_fee = TaxPercentage.handling_fee
    gst = TaxPercentage.gst_percentage * 0.01


    order = Order.find(params[:order][:id])
    # Write Order into Order History
    attributes = order.attributes
    attributes['order_id'] = attributes['id']
    order_history = OrderHistory.new(attributes.reject{|key, value| ['id'].include?key})
    order_history.save
    products = order.order_products

    product_histories = []
    products.each do |product|
      product_attribuets = product.attributes
      product_attribuets['order_history_id'] = order_history.id
      product_history = OrderProductHistory.new(product_attribuets.reject{|key, value| ['id'].include?key})
      product_histories.append(product_history)
    end

    order.assign_attributes(order_params)

    order.staff_id = Customer.find(order.customer_id).staff_id
    order.qty = products_params.values().map {|x| x['qty'].to_i }.sum
    order.handling_cost = order.qty * handling_fee
    order.last_updated_by = session[:user_id]

    products_container = []
    products_params.each do |product_id, product_params|
      if products.map(&:product_id).include? product_id.to_i
        product = products.where(product_id: product_id).first
        product.assign_attributes(product_params.permit(:price_luc, :qty, :discount, :price_discounted))

        product.display = (product.qty == 0) ? 0 : 1
        product.stock_previous = product.stock_current
        product.stock_current = product.qty
        product.stock_incremental = product.qty - product.stock_previous
      else
        product = OrderProduct.new(product_params.permit(:price_luc, :qty, :discount, :price_discounted))
        product.product_id = product_id
        product.order_id = order.id

        product.qty_shipped = 0
        product.base_price = product.price_luc / (1 + wet)

        product.stock_previous = 0
        product.stock_current = product.qty
        product.stock_incremental = product.qty

        product.display = 1
        product.damaged = 0
        product.created_by = session[:user_id]
      end
      product.order_discount = order.discount_rate
      product.price_handling = handling_fee
      product.price_inc_tax = product.price_discounted * (1 + gst)
      product.price_wet = (product.price_discounted / (1 + wet) - handling_fee) * wet
      product.price_gst = product.price_discounted * gst
      product.updated_by = session[:user_id]
      products_container.append(product)
    end

    products_container.map(&:save)
    product_histories.map(&:save)
    order.save

    flash[:success] = 'Edited'
    redirect_to action: 'details', order_id: order.id
  end

  def order_history
    @order = Order.find(params[:order_id])
  end

  private
  def order_params
    # total_tax -> GST
    # subtotal_tax -> WET
    params.require(:order).permit(:customer_id, :subtotal, :discount_rate, :discount_amount,\
                                  :shipping_cost, :total_inc_tax, :wet, :gst, \
                                  :customer_notes, :staff_notes, :address)
  end

  def products_params
    params.require(:order).require(:products)
  end
end
