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
    product_filtered_ids, @producer_country, @product_sub_type, @search_text = \
      products(params, staff_id, @status_id)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, product_filtered_ids, staff_id, @status_id)
  end

  def order_status
    customer_ids = (params[:search].nil?) ? [] : Customer.search_for(params[:search]).pluck("id")
    @per_page = params[:per_page] || Order.per_page
    order_function, direction = sort_order(params, :order_by_id, 'DESC')

    @orders = Order.include_all.where('status_id != 10').customer_filter(customer_ids)\
      .send(order_function, direction).paginate(per_page: @per_page, page: params[:page])
  end

  def status_check
    selected_orders = params[:selected_orders]
    if selected_orders.nil? || selected_orders.blank?
      flash[:error] = "Please Select Orders!"
      redirect_to :back
      return
    end
    @status_name = params[:commit]
    @status_id = Status.where("alt_name LIKE '#{@status_name}'").first.id
    @orders = Order.order_filter_by_ids(selected_orders)
  end

  def status_update
    selected_orders = params[:selected_orders] || []
    selected_orders = selected_orders.first.split unless selected_orders.blank? || selected_orders.count > 1

    # Print Shipping List
    if "Print Picking Sheet" == params[:commit] && !selected_orders.blank?
      # Print Picking Sheet
      # Due to Rails redirect conflicts
      pdf = print_shipping_sheet(selected_orders)
      send_data pdf.to_pdf, filename: "picking_sheet_#{session[:username]}_#{Date.today.to_s}.pdf" and return
    end

    # Group Update
    if ['Picked', 'Ready', 'Shipped'].include? params[:commit]
      status_id = 8 if params[:commit] == 'Picked'
      status_id = 9 if params[:commit] == 'Ready'
      status_id = 2 if params[:commit] == 'Shipped'
      Order.where(id: selected_orders).update_all(status_id: status_id)
      redirect_to controller: 'status', action: 'order_status' and return
    end

    # Individual Update
    # Skip current record
    if "Skip" == params[:commit]
    elsif "Approve" == params[:commit]
      Order.find(params[:order_id]).update(status_id: 3)
    elsif "Hold-Stock" == params[:commit]
      Order.find(params[:order_id]).update(status_id: 20)
    elsif "Hold-Price" == params[:commit]
      Order.find(params[:order_id]).update(status_id: 7)
    elsif "Hold-Other" == params[:commit]
      Order.find(params[:order_id]).update(status_id: 13)
    elsif "Create Label" == params[:commit]
      # TODO
      # Create Fastway Label & Create tracking information for orders
    elsif "Delivered" == params[:commit]
      Order.find(params[:order_id]).update(status_id: 12)
    elsif "Problem" == params[:commit]
      Order.find(params[:order_id]).update_attributes(params[:order])
    elsif !params[:order].nil?
      status = Status.find(params[:order][:status_id])
      order = Order.find(params[:order][:id])
      # Approved, Partially Paid, Unpaid, Paid, Hold-Accounts
      account_status = params[:order][:account_status]
      if account_status == "Hold-Account" && status.in_transit == 1
        flash[:error] = "Account Hold for Order#" + order.id.to_s
      elsif status.name == "Shipped"
        redirect_to controller: 'status', action: 'ship_orders', order_id: order.id and return
      elsif status.name == "Damaged"
        redirect_to controller: 'status', action: 'damage_orders', order_id: order.id and return
      elsif status.name == "Return Requested"
        redirect_to controller: 'status', action: 'return_orders', order_id: order.id and return
      else
        order.assign_attributes(params[:order].permit(:status_id, :account_status, :courier_status_id))
        order.save
      end
    else
      # Group Updated
    end

    if selected_orders.blank?
      redirect_to controller: 'order', action: 'all' and return
    else
      redirect_to controller: 'order', action: 'order_confirmation', order_id: selected_orders.first, selected_orders: selected_orders, status_id: params[:status_id]
      return
    end
  end

  def summary_with_product
    @status_id, @status_name = get_id_and_name(params)
    @product_id = params[:product_id]
    @product_name = params[:product_name]
    @num_orders = params[:num_orders]
    @qty = params[:qty]
    @status_qty = params[:status_qty]
    @total = params[:total]

    staff_id, @staff = staff_filter(params)
    @per_page, @orders, @products, @last_order_date = \
      orders(params, @product_id, staff_id, @status_id)
    @overall_stats = overall_stats_(params)
  end

  def overall_stats_(params)
    @selected_period, @period_types = define_period_types(params)
    @result = overall_stats('Order.order_product_filter(%s).status_filter(%s)' % \
       [@product_id, @status_id], :sum_order_product_qty, @selected_period, nil)
  end

  def fetch_last_products
    order_ids = Order.where(customer_id: params[:customer_id]).map(&:id)
    product_ids = OrderProduct.where("order_id IN (?) AND created_at > ?", order_ids, (Date.today - 3.month).to_s(:db)).map(&:product_id)
    @products = Product.where(id: product_ids)
    respond_to do |format|
      format.js
    end
  end
end

private
  def order_params
    params.require(:order).permit(:id, :status_id, :courier_status_id, :account_status)
  end
