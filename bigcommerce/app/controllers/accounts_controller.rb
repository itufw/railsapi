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

        @date_column = params[:date_column] || 'due_date'
        @monthly = params[:monthly] || 'monthly'

        @checked_due_date, @checked_invoice_date = date_column_checked(@date_column)
        @checked_monthly, @checked_daily = monthly_checked(@monthly)

        # sorting via sort_order -> find the function called order_by_name
        order_function, direction = sort_order(params, 'order_by_name', 'ASC')

        contacts, @search_text = contact_param_filter(params)
        # @contacts = contacts.outstanding_is_greater_zero.period_select(@end_date).send(order_function, direction).paginate( per_page: @per_page, page: params[:page])
        @contacts = contacts.outstanding_is_greater_zero.is_customer.period_select(@end_date)

        if order_function.start_with?('order_by_invoice')
            # .split('|')
            order_function, sort_date_start, sort_date_end = order_function.split('|')
            @contacts = XeroContact.select('*').from(@contacts.send(order_function, direction, sort_date_start, sort_date_end, @date_column))
        else
            @contacts = @contacts.send(order_function, direction)
        end
        @contacts = @contacts.paginate(per_page: @per_page, page: params[:page])
        @invoices = {}
        @contacts.each do |c|
            @invoices[c.id] = c.xero_invoices.has_amount_due.period_select(@end_date)
        end
    end

    def contact_invoices
        # Check the ratio to check if this email a preview or sending directly to the customer
        @checked_send_email_to_self, @checked_send_email_not_to_self = email_preview(params[:send_email_to_self])

        @customer = params[:contact_id] ? Customer.include_all.filter_by_contact_id(params[:contact_id]) : Customer.include_all.find(params[:customer_id])

        @end_date = return_end_date_invoices(params[:end_date]) || Date.today
        @monthly = params[:monthly] || 'monthly'
        @checked_monthly, @checked_daily = monthly_checked(@monthly)

        @cn_op = credit_note_and_overpayment(@customer.xero_contact_id)

        # multiple contact people
        # xeroizer only provides email_address, the details of phone number should be discussed
        @contact_people = XeroContactPerson.all_contact_people(@customer.xero_contact_id)

        # calculate the invoice table based
        # function located in helper -> accounts_helper
        @amount_due = get_invoice_table(@customer.id, @monthly, @end_date)
    end

    def email_edit
        @cn_op = (params[:cn_op].nil?) ? {} : unzip_cn_op(params[:cn_op])
        @total_remaining_credit = (@cn_op.map { |x| x[:remaining_credit] }).sum

        selected_invoices = params[:selected_invoices]
        customer_id = params[:customer_id]

        @xero_contact = XeroContact.where(skype_user_name: customer_id).first

        # filter the unexpected invoices missing
        if ['Send Reminder', 'Send Missed Payment'].include? params[:commit]
            unless selected_invoices
                flash[:error] = 'Please Select the invoice!'
                redirect_to :back
            end
            @over_due_invoices = XeroInvoice.has_amount_due.where('invoice_number IN (?)', selected_invoices).order(:due_date)
            @missing_invoice = true
        else
            @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(xero_contact_id: @xero_contact.xero_contact_id).order(:due_date)
            @missing_invoice = false
        end
        @customer_name = @xero_contact.name
        @customer_firstname = @xero_contact.firstname

        # Check the ratio to check if this email a preview or sending directly to the customer
        @checked_send_email_to_self, checked_send_email_not_to_self = email_preview(params[:send_email_to_self])

        # helpers -> accounts_helper
        # assigned value to @email_title via this function
        @email_content = get_email_content(params, session[:user_id], customer_id, selected_invoices)
    end

    def send_reminder
        cn_op = params[:cn_op]
        # this function is located in helpers -> accounts_helper
        email_type, customer_id, receive_address, email_content, selected_invoices, email_cc, email_bcc = get_data_from_email_form(params)

        # Check the ratio to check if this email a preview or sending directly to the customer
        checked_send_email_to_self = email_preview(params[:checked_send_email_to_self])
        email_subject = params[:email_subject]

        staff_id = session[:user_id]
        ReminderMailer.send_overdue_reminder(customer_id, email_subject, staff_id, email_content, receive_address, email_cc, email_bcc, email_type, selected_invoices, cn_op).deliver_now
        flash[:success] = 'Email Sent'

        redirect_to action: 'contact_invoices', customer_id: customer_id
    end
end
