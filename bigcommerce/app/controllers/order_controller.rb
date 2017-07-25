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
    	@order_id = params[:order_id]
      @per_page = params[:per_page] || Order.per_page
    	@order = Order.include_all.order_filter_(@order_id).paginate( per_page: @per_page, page: params[:page])

      @tasks = Task.active_tasks.order_tasks(@order_id).order_by_id('DESC')
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
    @order = CmsOrder.new
  end

  def cms_order_all
    @orders = CmsOrder.all
  end

  def save_order
    order = CmsOrder.new
    if order.update_attributes(cms_order_params)
      qty = 0
      product_list = params.keys.select { |x| x.start_with?('product_name ') }.map(&:split).map(&:last)
      product_list.each do |product_id|
        order_product = CmsOrderProduct.new(cms_order_id: order.id, product_id: product_id, qty: params['qty '+product_id], base_price: params['price_luc '+product_id], price_ex_tax: params['price '+ product_id])
        order_product.save

        qty += params['qty '+product_id].to_i
      end
      order.staff_id = Customer.find(order.customer_id).staff_id
      order.qty = qty
      order.save
      redirect_to action: 'cms_order_all'
    else
      redirect_to :back
    end
  end

  def generate_invoice
    order = CmsOrder.find(params[:order_id])
    customer = Customer.find(order.customer_id)
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(
          :template => 'pdf/cms_order_invoice.pdf',
          :locals => {order: order, customer: customer}
          )
      )
      send_data pdf, filename: "#{order.id}.pdf", type: :pdf
  end

  private
  def cms_order_params
    # total_tax -> GST
    # subtotal_tax -> WET
    params.require(:cms_order).permit(:customer_id, :subtotal_inc_tax, :discount_rate, :discount_amount,\
                                     :subtotal_tax, :total_tax, :total_inc_tax,\
                                     :customer_notes, :staff_notes)
  end


end
