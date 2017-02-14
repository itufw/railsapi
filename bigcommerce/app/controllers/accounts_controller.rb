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

    @customer = params[:contact_id] ? Customer.include_all.filter_by_contact_id(params[:contact_id]) : Customer.include_all.find(params[:customer_id])

    @end_date = params[:end_date] || Date.today

    @monthly = params[:monthly] || "monthly"

    # calculate the invoice table based
    # function located in helper -> accounts_helper
    @amount_due = get_invoice_table(@customer.id,@monthly,@end_date)


  end

  def email_edit
    selected_invoices = params[:selected_invoices]


    customer_id = params[:customer_id]
    @xero_contact = XeroContact.where(:skype_user_name => customer_id).first

    # filter the unexpected invoices missing
    if ["Send Reminder","Send Missed Payment"].include? params[:commit]
      unless selected_invoices
        flash[:error] = "Please Select the invoice!"
        redirect_to :back
      end
      @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where("invoice_number IN (?)",selected_invoices).order(:due_date)
    else
      @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(:xero_contact_id => @xero_contact.xero_contact_id).order(:due_date)
    end


    @customer_name = @xero_contact.name

    @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(:xero_contact_id => @xero_contact.xero_contact_id).order(:due_date)

    # Check the ratio to check if this email a preview or sending directly to the customer
    @checked_send_email_to_self, checked_send_email_not_to_self = email_preview(params[:send_email_to_self])



    # form builder
    @email_content = AccountEmail.new

    @email_content.receive_address = @checked_send_email_to_self ? Staff.find(session[:user_id]).email : @xero_contact.email

    @email_content.email_type = params[:commit]

    unless @checked_send_email_to_self
      @email_content.cc = Staff.find(Customer.find(customer_id).staff_id).email
      @email_content.bcc = "emailtosalesforce@y-5cvcy6yhzo3z4984r5f5htqn7.9yyfmeag.9.le.salesforce.com"
    end

    # set default_email_content, this function is located in helpers-> accounts_helper
    @email_content.content, @email_content.content_second, @email_title = default_email_content(params[:commit])

    @email_content.customer_id = customer_id
    @email_content.selected_invoices = selected_invoices
  end

  def send_reminder
    # this function is located in helpers -> accounts_helper
    email_type, customer_id, receive_address, email_content, selected_invoices, email_cc, email_bcc = get_data_from_email_form(params)

    # Check the ratio to check if this email a preview or sending directly to the customer
    checked_send_email_to_self = email_preview(params[:checked_send_email_to_self])
    email_subject = params[:email_subject]

    staff_id = session[:user_id]

    ReminderMailer.send_overdue_reminder(customer_id, email_subject, staff_id, email_content, receive_address, email_cc, email_bcc, email_type, selected_invoices).deliver_now
    flash[:success] = "Email Sent"

    redirect_to action: "contact_invoices", customer_id: customer_id

  end

end
