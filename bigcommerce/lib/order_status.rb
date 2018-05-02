require 'fastway.rb'
require 'fastway_api.rb'
module OrderStatus
  include FastwayApi

  def order_status_handler(params, order_params, user_id)
    selected_orders = params[:selected_orders] || []
    selected_orders = selected_orders.first.split unless selected_orders.blank? || selected_orders.count > 1

    if params[:commit].nil? && !selected_orders.blank?
      Order.where(id: selected_orders).map{ |x| x.update_attributes({status_id: params[:status], last_updated_by: user_id})}
      return ['All', '']
    end

    # Print Shipping List
    if "Print Picking Slip" == params[:commit] && !selected_orders.blank?
      # Print Picking Sheet
      # Due to Rails redirect conflicts
      pdf = print_picking_slip(selected_orders)
      return ['print_picking_slip', pdf]
    elsif "Print Invoices" == params[:commit] && !selected_orders.blank?
      pdf = print_invoices(selected_orders)
      return ['print_invoice', pdf]
    elsif "Print Picking Sheets" == params[:commit] && !selected_orders.blank?
      pdf = print_shipping_sheet(selected_orders)
      return ['print_picking_sheet', pdf]
    elsif "Print PoD" == params[:commit] && !selected_orders.blank?
      pdf = print_pod(selected_orders)
      return ['print_pod', pdf]
    elsif 'Export Excel' == params[:commit] && !selected_orders.blank?
      return ['export_scotpac', selected_orders]
    elsif 'Exported!' == params[:commit] && !selected_orders.blank?
      Order.where(id: selected_orders).update_all(scot_pac_load: 1)
      return ['scotpac_loaded', selected_orders]
    end

    case params[:commit]
    when 'Picked'
      Order.where(id: selected_orders).update_all(status_id: 27, last_updated_by: user_id)
      return ['Group Update', '']
    when 'Ready'
      Order.where(id: selected_orders).update_all(status_id: 25, last_updated_by: user_id)
      return ['Group Update', '']
    when 'Shipped'
      Order.where(id: selected_orders).map{|x| x.update_attributes({status_id: 2, last_updated_by: user_id}) }
      return ['Group Update', '']
    when 'Approve'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 9, last_updated_by: user_id}))
    when 'Hold-Stock'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 20, last_updated_by: user_id}))
    when 'Hold-Price'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 26, last_updated_by: user_id}))
    when 'Hold-Other'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 24, last_updated_by: user_id}))
    when 'Delivered'
      order = Order.find(params[:order_id])
      if !order.xero_invoice_id.nil? && order.xero_invoice.amount_due==0
        Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 10, last_updated_by: user_id}))
      else
        Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 12, last_updated_by: user_id}))
      end
    when 'Problem'
      Order.find(params[:order_id]).update_attributes(order_params)
    when 'Complete'
      Order.find(params[:order_id]).update_attributes(order_params.merge({status_id: 10, last_updated_by: user_id}))
    when 'Skip'
      # Just Skip
    when 'Create Label'
      # Create Fastway Label & Create tracking information for orders
      # IF order_params[:courier_status_id] == 3 -> Create FASTWAY Label
      # Else: just record the label number
      if order_params[:courier_status_id] == '3'
        order = Order.find(params[:order_id])
        order.update_attributes(order_params.reject{|key, value| key == 'courier_status_id' })
        result = Fastway.new.add_consignment(order, params['dozen'].to_i, params['half-dozen'].to_i)
        begin
          order.update_attributes(order_params.reject{|key, value| key == 'courier_status_id' }.merge({track_number: result['result']['LabelNumbers'].join(';'), courier_status_id: 4, date_shipped: Time.now.to_s(:db), last_updated_by: user_id}))
          order.customer.update_attributes(order_params.select{|key, value| ['SpecialInstruction1', 'SpecialInstruction2', 'SpecialInstruction3'].include?key}) unless params[:customer_instruction_update].nil? || params[:customer_instruction_update]==""
          flash[:success] = "Label Printed"
        rescue
          flash[:error] = 'Fail to connect Fastway, Check the Shipping Address'
          flash[:error] = result['error'] unless result.nil? || result['error'].nil?
          selected_orders.unshift(params[:order_id])
          return ['Label Error', selected_orders]
        end
        # create label with fastway
      else
        Order.find(params[:order_id]).update_attributes(order_params.merge({date_shipped: Time.now.to_s(:db), last_updated_by: user_id, eta: Date.today.to_s(:db)}))
      end
    else
      if !params[:order].nil?
        status = Status.find(params[:order][:status_id])
        order = Order.find(params[:order][:id])
        # Approved, Partially Paid, Unpaid, Paid, Hold-Accounts
        account_status = params[:order][:account_status]
        if account_status == "Hold-Account" && status.in_transit == 1
          flash[:error] = "Account Hold for Order#" + order.id.to_s
        else
          order.assign_attributes(order_params)
          order.save
        end
      end
    end

    unless params[:order][:customer].nil?
      customer_params = params[:order][:customer].permit(:street, :city, :state, :street_2, :postcode, :country, :company)
      customer = Customer.joins(:orders).where('orders.id = ?', params[:order_id]).first.update_attributes(customer_params)
    end

    return ['All', ''] if selected_orders.blank?
    ['Next', selected_orders]
  end

  # select an invoice based on the type of an order i.e. retail sale of beer,
  # wholesale of wine, etc.
  def print_single_invoice(order)
    customer = order.customer

    if is_beer_order(order)
      if customer.cust_type_id == 1
        template = 'pdf/rs_beer_order_invoice.pdf'  # retail beers
      elsif customer.cust_type_id == 2
        template = 'pdf/ws_beer_order_invoice.pdf'  # wholesale beers
      else
        template = 'pdf/rs_beer_order_invoice.pdf'  # retail beers
      end
    else
      if customer.cust_type_id == 1
        template = 'pdf/retail_order_invoice.pdf'   # retail wines
      elsif customer.cust_type_id == 2
        template = 'pdf/order_invoice.pdf'          # wholesale wines
      else
        template = 'pdf/retail_order_invoice.pdf'   # retail wines
      end
    end

    order_invoice = WickedPdf.new.pdf_from_string(
      render_to_string(
          :template => template,
          :locals => {order: order, customer: customer}
          )
      )

    order_invoice
  end

  def print_invoices(selected_orders)
    orders = Order.where(id: selected_orders)
    pdf = CombinePDF.new
    orders.each do |order|
      order_invoice = print_single_invoice(order)
      pdf << CombinePDF.parse(order_invoice)
    end
    pdf
  end

  def print_picking_slip(selected_orders)
    orders = Order.where(id: selected_orders)
    picking_slips = CombinePDF.new
    orders.each do |order|
      packing_slip = WickedPdf.new.pdf_from_string(
        render_to_string(
            :template => 'pdf/packing_slip.pdf',
            :locals => {order: order, customer: order.customer}
            )
        )
      picking_slips << CombinePDF.parse(packing_slip)
    end
    picking_slips
  end

  def print_shipping_sheet(selected_orders)
    picking_sheet = WickedPdf.new.pdf_from_string(
      render_to_string(
          template: 'pdf/picking_sheet.pdf',
          locals: {order_products: OrderProduct.where(order_id: selected_orders, display: 1) }
          )
      )
    picking_sheet
  end

  def print_pod(selected_orders)
    orders = Order.where(id: selected_orders)
    order_pods = CombinePDF.new

    orders.each do |order|
      if !order.proof_of_delivery.file.nil?
        order_pods << CombinePDF.parse(open(order.proof_of_delivery.to_s).read)
      elsif FastwayTrace.pod_available(order.id).first
        item = FastwayConsignmentItem.filter_order(order.id).first
        pod = WickedPdf.new.pdf_from_string(
          render_to_string(
              :template => 'pdf/proof_of_delivery.pdf',
              :locals => {order: Order.find(order.id), item: item }
              )
          )
        order_pods << CombinePDF.parse(pod)
      end
    end

    order_pods
  end
end
