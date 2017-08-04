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
    @status_id, @status_name = get_id_and_name(params)
    staff_id, @staff = staff_filter(params)
    search_text = params[:search]
    customer_ids = (search_text.nil?) ? [] : Customer.search_for(search_text).pluck("id")
    @per_page = params[:per_page] || Order.per_page
    order_function, direction = sort_order(params, :order_by_id, 'DESC')

    @orders = Order.include_all.status_filter(@status_id).staff_filter(staff_id)\
                .customer_filter(customer_ids).send(order_function, direction)\
                .paginate(per_page: @per_page, page: params[:page])

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

    if "Next" == params[:commit]
      # Next one
    elsif "Print Picking Sheet" == params[:commit] && !selected_orders.blank?
      # Print Picking Sheet
      # Due to Rails redirect conflicts
      orders = Order.where(id: selected_orders)
      picking_sheet = WickedPdf.new.pdf_from_string(
        render_to_string(
            :template => 'pdf/picking_sheet.pdf',
            :locals => {orders: orders }
            )
        )
      send_data picking_sheet, filename: "picking_sheet_#{session[:username]}_#{Date.today.to_s}.pdf", type: :pdf and return
    elsif 'Picked' == params[:commit]
      orders = Order.where(id: selected_orders)
      orders.update_all(status_id: 8)
      redirect_to controller: 'status', action: 'order_status', status_id: 8, status_name: 'Picking' and return
    elsif 'Ready' == params[:commit]
      orders = Order.where(id: selected_orders)
      orders.update_all(status_id: 9)
      redirect_to controller: 'status', action: 'order_status', status_id: 9, status_name: 'Ready' and return
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
      redirect_to controller: 'order', action: 'details', order_id: selected_orders.first, selected_orders: selected_orders, status_id: params[:status_id]
      return
    end
  end

  def ship_orders
    p = c
    # TODO
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
end

private
  def order_params
    params.require(:order).permit(:id, :status_id, :courier_status_id, :account_status)
  end
