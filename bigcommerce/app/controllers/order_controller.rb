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

    # Current used as Status Update
    def order_confirmation
      if params[:selected_orders].nil?
        @order = Order.find(params[:order_id])
      elsif params[:selected_orders].blank?
        redirect_to controller: 'order', action: 'all'
        return
      else
        @order =  Order.find(params[:selected_orders].delete_at(0))
        @selected_orders = params[:selected_orders]
        @selected_status_id = params[:status_id]
      end
    end

	# Displays all details about an order
	# How do I get to this ? Click on a Order ID anywhere on the site
	def details
    @order_id = params[:order_id]

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
    redirect_to controller: 'activity', action: 'add_note', customer_id: order_params[:customer_id] and return if params["button"] == "new_note"
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
    products = order.order_products

    order.assign_attributes(order_params)
    order_attributes = {'staff_id': Customer.find(order.customer_id).staff_id,\
      'qty': products_params.values().map {|x| x['qty'].to_i }.sum,\
      'handling_cost': products_params.values().map {|x| x['qty'].to_i }.sum * handling_fee,\
      'last_updated_by': session[:user_id]}
    order.assign_attributes(order_attributes)

    products_container = []
    products_params.each do |product_id, product_params|
      if products.map(&:product_id).include? product_id.to_i
        # update
        product = products.where(product_id: product_id).first
        product.assign_attributes(product_params.permit(:price_luc, :qty, :discount, :price_discounted))
        product_attributes = {'display': (product.qty == 0) ? 0 : 1, 'stock_previous': product.stock_current,\
          'stock_current': product.qty, 'stock_incremental': product.qty - product.stock_current,\
          'order_discount': order.discount_rate, 'price_handling': handling_fee,\
          'price_inc_tax': product.price_discounted * (1 + gst),\
          'price_wet': (product.price_discounted / (1 + wet) - handling_fee) * wet,\
          'price_gst': product.price_discounted * gst, 'updated_by': session[:user_id]}
      else
        # insert
        product = OrderProduct.new(product_params.permit(:price_luc, :qty, :discount, :price_discounted))
        product_attributes = {'product_id': prduct_id, 'order_id': order.id, 'qty_shipped': 0,\
          'base_price': product.price_luc / (1 + wet), 'stock_previous': 0, 'stock_current': product.qty,\
          'stock_incremental': product.qty, 'display': 1, 'damaged': 0, 'created_by': session[:user_id],\
          'order_discount': order.discount_rate, 'price_handling': handling_fee,\
          'price_inc_tax': product.price_discounted * (1 + gst),\
          'price_wet': (product.price_discounted / (1 + wet) - handling_fee) * wet,\
          'price_gst': product.price_discounted * gst, 'updated_by': session[:user_id]}
      end
      product.assign_attributes(product_attributes)
      products_container.append(product)
    end

    order.save
    products_container.map(&:save)

    flash[:success] = 'Edited'
    redirect_to controller: 'activity', action: 'add_note', customer_id: order_params[:customer_id] and return if params["button"] == "new_note"
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
                                  :customer_notes, :staff_notes, :shipping_address, :modified_wet,\
                                  :billing_address, :delivery_instruction)
  end

  def products_params
    params.require(:order).require(:products)
  end
end
