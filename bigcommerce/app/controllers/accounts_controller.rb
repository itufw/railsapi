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

    @checked_due_date, @checked_invoice_date = date_column_checked(@date_column)

    # sorting via sort_order -> find the function called order_by_name
    order_function, direction = sort_order(params, 'order_by_name', 'ASC')

    contacts, @search_text = contact_param_filter(params)
    @contacts = contacts.outstanding_is_greater_zero.period_select(@end_date).send(order_function, direction).paginate( per_page: @per_page, page: params[:page])

    @invoices = Hash.new
    @contacts.each do |c|
      @invoices[c.id] = c.xero_invoices.has_amount_due.period_select(@end_date)
    end
  end

  def contact_invoices
    @amount_due = params[:amount_due]

    @customer = Customer.include_all.filter_by_contact_id(params[:contact_id])

  end

  def send_reminder
    # p =c
    # TODO Have not finished yet!
    @selected_invoices = params[:selected_invoices]
    @customer_id = params[:customer_id]
    ReminderMailer.reminder_email(@customer_id,@selected_invoices).deliver_now
    redirect_to :back

  end

end
