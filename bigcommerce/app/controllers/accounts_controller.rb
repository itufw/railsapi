class AccountsController < ApplicationController

  before_action :confirm_logged_in

  include ModelsFilter
  # include AccountsFilter
  include DisplayHelper
  include ProductVariations

  def overdue_table

  end

  def contacts
    @per_page = params[:per_page] || Customer.per_page


    @date_column = params[:date_column] || "due_date"
    if "due_date".eql? @date_column
      @checked_due_date = true
      @checked_invoice_date = false
    else
      @checked_invoice_date = true
      @checked_due_date = false
    end

    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    @staff, customers, @search_text, staff_id, @cust_style = customer_param_filter(params, session[:user_id])
    @customers = customers.include_all.xero_contact_is_not_null.outstanding_is_greater_zero.send(order_function, direction).paginate( per_page: @per_page, page: params[:page])

    # @customers = customer_outstanding_greater_zero(params)
    @invoices = Hash.new
    @customers.each do |c|
      @invoices[c.id] = c.xero_contact.xero_invoices.has_amount_due
    end
  end

  def customer_invoices
    @amount_due = params[:amount_due]

    @customer = Customer.include_all.filter_by_id(params[:customer_id])
  end

  def send_reminder
    # ReminderMailer.reminder_email("test").deliver_now
    p =c
    redirect_to :back

  end
end
