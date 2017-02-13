require 'models_filter.rb'
require 'accounts_helper.rb'
require 'dates_helper.rb'

class AccountsController < ApplicationController

  before_action :confirm_logged_in

  include ModelsFilter
  include AccountsHelper
  include DatesHelper

  def contacts
    @end_date = return_end_date_invoices(params[:end_date])
    @per_page = params[:per_page] || XeroContact.per_page
    @date_column = params[:date_column] || "due_date"
    @monthly = params[:monthly] || "monthly"

    @checked_due_date, @checked_invoice_date = date_column_checked(@date_column)
    @checked_monthly, @checked_daily = monthly_checked(@monthly)

    # sorting via sort_order -> find the function called order_by_name
    order_function, direction =  sort_order(params, 'order_by_name', 'ASC')

    contacts, @search_text = contact_param_filter(params)
    # @contacts = contacts.outstanding_is_greater_zero.period_select(@end_date).send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
    @contacts = contacts.outstanding_is_greater_zero.period_select(@end_date)

    if order_function.start_with?("order_by_invoice")
      # .split('|')
      order_function, sort_date_start, sort_date_end = order_function.split('|')
      @contacts = XeroContact.select('*').from(@contacts.send(order_function, direction,sort_date_start,sort_date_end,@date_column))
    else
      @contacts = @contacts.send(order_function, direction)
    end
    @contacts = @contacts.paginate( per_page: @per_page, page: params[:page])
    @invoices = Hash.new
    @contacts.each do |c|
      @invoices[c.id] = c.xero_invoices.has_amount_due.period_select(@end_date)
    end
  end

  def contact_invoices

    # Check the ratio to check if this email a preview or sending directly to the customer
    @checked_send_email_to_self, @checked_send_email_not_to_self = email_preview(params[:send_email_to_self])

    @amount_due = params[:amount_due]

    @customer = Customer.include_all.filter_by_contact_id(params[:contact_id])

    @end_date = params[:end_date] || Date.today

    @monthly = params[:monthly] || "monthly"
  end

  def email_edit
    @selected_invoices = params[:selected_invoices]
    @customer_id = params[:customer_id]
    xero_contact = XeroContact.where(:skype_user_name => @customer_id).first
    @customer_name = xero_contact.name

    @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(:xero_contact_id => xero_contact.xero_contact_id).order(:due_date)

    # Check the ratio to check if this email a preview or sending directly to the customer
    @checked_send_email_to_self, @checked_send_email_not_to_self = email_preview(params[:send_email_to_self])

    @commit = params[:commit]
  end

  def send_reminder
    selected_invoices = params[:selected_invoices]
    @selected_invoices = selected_invoices.split()

    email_content = params[:content]

    @customer_id = params[:customer_id]

    # Check the ratio to check if this email a preview or sending directly to the customer
    checked_send_email_to_self = email_preview(params[:checked_send_email_to_self])

    staff_id = session[:user_id]

    case params[:commit]
    when "Send Reminder", "Send Missed Payment"
        if params[:selected_invoices]
          ReminderMailer.reminder_email(@customer_id,@selected_invoices, checked_send_email_to_self,staff_id,email_content).deliver_now
          flash[:success] = "Email Sent"
        else
          flash[:error] = "Please Select the invoice!"
        end
      # different template for overdue_reminder_body based on the button user clicked
    when "Send Overdue Reminder"
      ReminderMailer.send_overdue_reminder(@customer_id,"overdue",checked_send_email_to_self,staff_id,email_content).deliver_now
      flash[:success] = "Email Sent"
    when "Send 60 Days Overdue Reminder"
      ReminderMailer.send_overdue_reminder(@customer_id,"overdue_60days",checked_send_email_to_self,staff_id,email_content).deliver_now
      flash[:success] = "Email Sent"
    when "Send 90 Days Overdue Reminder"
      ReminderMailer.send_overdue_reminder(@customer_id,"overdue_90days",checked_send_email_to_self,staff_id,email_content).deliver_now
      flash[:success] = "Email Sent"
    when "Send New Order Hold"
      ReminderMailer.send_overdue_reminder(@customer_id,"new_order_hold",checked_send_email_to_self,staff_id,email_content).deliver_now
      flash[:success] = "Email Sent"
    end
    redirect_to :back
  end

end
