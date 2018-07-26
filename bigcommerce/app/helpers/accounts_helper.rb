module AccountsHelper
    include ActionView::Helpers::NumberHelper

    def contacts_selection(params, end_date, per_page, date_column)

      # search the customer
      search_text = params[:search]
      # filter based on the staff
      selected_staff = params[:selected_staff]

      # select customers with the balance above zero
      contacts = XeroContact.joins(:customer).select("xero_contacts.*, customers.staff_id").\
                  search_filter(search_text).outstanding_is_greater_zero.is_customer.uniq

      contacts = contacts.where("customers.staff_id IN (?)", selected_staff) unless selected_staff.nil? || selected_staff.blank?

      # contacts = (params[:selected_months].blank?) ? contacts.period_select(end_date.to_s) : contacts.limited_period_select(params[:selected_months], date_column)
      contacts = (params[:selected_months].blank?) ? contacts : contacts.limited_period_select(params[:selected_months], date_column)

      # sorting via sort_order -> find the function called order_by_name
      order_function, direction = sort_order(params, 'order_by_name', 'ASC')

      if order_function.start_with?('order_by_invoice')
          # .split('|')
          order_function, sort_date_start, sort_date_end = order_function.split('|')
          contacts = XeroContact.select('*').from(contacts.send(order_function, direction, sort_date_start, sort_date_end, date_column))
      else
          contacts = contacts.send(order_function, direction)
      end

      contacts = contacts.paginate(per_page: per_page, page: params[:page])
      [contacts, search_text, selected_staff]
    end

    def credit_note_and_overpayment(xero_contact_id, xero_invoices_ids)
        op = XeroOverpayment.joins(:xero_op_allocations).get_remaining_credit(xero_contact_id).where('xero_overpayments.remaining_credit > 0 OR xero_op_allocations.invoice_number IN (?)', xero_invoices_ids)
        op += XeroOverpayment.get_remaining_credit(xero_contact_id).where('xero_overpayments.remaining_credit > 0')
        op = op.uniq
        cn = XeroCreditNote.joins(:xero_cn_allocations).get_remaining_credit(xero_contact_id).where('xero_credit_notes.remaining_credit > 0 OR xero_cn_allocations.invoice_number IN (?)', xero_invoices_ids)
        cn_s = XeroCreditNote.get_remaining_credit(xero_contact_id).where('xero_credit_notes.remaining_credit > 0')
        cn += cn_s
        cn = cn.uniq

        # op = XeroOverpayment.get_remaining_credit(xero_contact_id).where('remaining_credit > 0')
        # cn = XeroCreditNote.get_remaining_credit(xero_contact_id).where('remaining_credit > 0')
        cn_op = {}
        op.each do |o|
            reference = ''
            op_allocation = XeroOpAllocation.where("xero_overpayment_id = '#{o.xero_overpayment_id}' ")

            op_allocation.each do |opa|
                reference += "Order##{opa.invoice_number} applied #{opa.applied_amount}  \n"
            end
            cn_op["Overpayment_#{o.date.year}_#{o.date.month}_#{o.date.day}"] = { sub_total: o.sub_total, total: o.total,\
                                                                                  remaining_credit: o.remaining_credit, date: o.date, reference: reference,\
                                                                                  status: 'Overpayment' }
        end

        cn.each do |c|
            cn_op[c.credit_note_number] = { sub_total: c.sub_total, total: c.total,\
                                            remaining_credit: c.remaining_credit, date: c.date, reference: c.reference,\
                                            status: c.credit_note_number }
        end

        cn_op
    end

    def unzip_cn_op(cn_op_array)
        cn_op = []
        cn_op_array.each do |co|
            status, date, remaining_credit = co.split(' ')
            co_op_item = { status: status, date: date, remaining_credit: remaining_credit.to_f }
            cn_op.push(co_op_item)
        end
        cn_op
    end

    def different_orders_checked(all)
        return true, false if 'all'.eql? all
        [false, true]
    end

    def email_preview(email_ratio)
        return false, true if 'no'.eql? email_ratio
        [true, false]
    end

    def default_email_content(commit, cn_op)
        cn_op_amount = 0
        cn_op_amount = cn_op.map { |x| x[:remaining_credit] }.sum unless cn_op.nil? || cn_op.blank?

        email_content = ''
        content_second_half = ''
        email_title = ''
        case commit
        when 'Send Reminder', 'Send Missed Payment'
            email_content = "Hi #{@customer_firstname},<br><br>
                            Thanks for the recent payment that was made to our account.<br><br>
                            Could I please refer you to an invoice that has been missed that we’re still awaiting payment for. The details are below.<br><br>"
            content_second_half = "I’ve attached a copy of the invoice(s) and the Proof of Delivery (POD) in case you are missing them in your records.<br><br>
                                  Thanks for the help and if you have any questions please be in contact.<br><br>"
            email_title = "MISSING INVOICE PAYMENT – Untapped Fine Wines – #{@customer_name}"

        when 'Send Overdue Reminder'
            email_content = "Hi #{@customer_firstname},<br><br>
                            We have outstanding balance for wine that was delivered for <b>#{@customer_name}</b> total <span class=\"wysiwyg-color-red\">#{number_to_currency(@over_due_invoices.sum(:amount_due) - cn_op_amount)}</span>. Please see the details below."
            content_second_half = "This balance is now <a style=\"color: red\">overdue</a> and we require payment of the amount provided above and repeated in the attached statement in order to continue to provide credit terms on a regular basis.<br><br>
                                  Can you please examine this and either give me a call or reply to this email as to when the outstanding amount can be settled.<br><br>
                                  I’ve attached a copy of the invoice(s) in case you are missing them in your records.<br><br>
                                  If you have any questions regarding your account please be in contact.<br><br>
                                  We appreciate your help in having this paid promptly."
            email_title = "OVERDUE REMINDER – Untapped Fine Wines – #{@customer_name}"

        when 'Send 60 Days Overdue Reminder'
            email_content = "Hi #{@customer_firstname},<br><br>
                            We have outstanding balance of <span class=\"wysiwyg-color-red\">#{number_to_currency(@over_due_invoices.sum(:amount_due) - cn_op_amount)} </span> for <b>#{@customer_name}</b>. Please see the details below.<br><br>
                            Until this overdue amount is settled any new order must be paid for prior to being dispatched<br><br>"
            content_second_half = "If you have any questions regarding your account please be in contact.<br><br>
                                  Attached are copies of the invoice(s) listed above in case they are missing from your records.<br><br>
                                  We appreciate your help in having this paid promptly.<br><br>"
            email_title = "OVERDUE PAYMENT REQUIRED – Untapped Fine Wines – #{@customer_name}"

        when 'Send 90 Days Overdue Reminder'
            email_content = "Hi #{@customer_firstname},<br><br>
                            We have outstanding balance of <span class=\"wysiwyg-color-red\">#{number_to_currency(@over_due_invoices.sum(:amount_due) - cn_op_amount)}</span> for <b>#{@customer_name}</b>. Some of this wine is more than 90 days overdue. The details are listed below.
                            We cannot continue to provide credit terms for your account on a normal basis. Until any overdue amount is cleared all new invoice must be paid for on creation before they can be shipped.
                            We have made repeated attempts to address this outstanding amount with you and now we require immediate payment.<br><br>"
            content_second_half = "Please be in contact with myself on 03 9676 9663 to discuss when we can expect to receive payment. If we fail to receive contact from you across the coming week we will begin <b>recovery actions </b>. Any costs relating to recovery actions will be passed on to your business. Please be aware that these recovery costs can be costly.<br><br>
                                  Attached are copies of the invoice(s) listed above in case they are missing from your records.<br><br>
                                  We appreciate your help and in responding to this quickly.<br><br>"
            email_title = "FINAL NOTICE PAYMENT REQUIRED, 90+ Days Overdue – Untapped Fine Wines – #{@customer_name}"

        when 'Send New Order Hold'
            email_content = "Hi #{@customer_firstname},<br><br>
                            We have an order for <b>#{@customer_name}</b> that was entered today that I’d like to have despatched for you today. In reviewing your account there are some amounts that are quite overdue. This is listed below for your reference. Could you please let me know when this amount can be paid?
                            Until I hear back from you we won’t be able to ship the wine.<br><br>"
            content_second_half = "I’ve attached a copy of the invoice(s) in case you are missing them in your records.<br><br>
                                  Thanks for the help and if you have any questions please be in contact.<br><br>"
            email_title = "ORDER ON HOLD – Untapped Fine Wines – #{@customer_name}"

          end
        [email_content, content_second_half, email_title]
    end

    def get_data_from_email_form(params)
        #     "checked_send_email_to_self"=>"true",
        # "account_email"=>{"email_type"=>"Send Overdue Reminder",
        # "customer_id"=>"1317",
        # "selected_invoices"=>"",
        # "receive_address"=>"angelica.deza17@gmail.com",
        # "content"=>"temp"},
        account_email = params[:account_email]

        email_type = account_email[:email_type] || 'Send Overdue Reminder'
        customer_id = account_email[:customer_id]
        receive_address = account_email[:receive_address]

        content = [account_email[:content], account_email[:content_second]]

        selected_invoices = account_email[:selected_invoices].split

        email_cc = account_email[:cc]
        email_bcc = account_email[:bcc]

        # email_type, customer_id, receive_address, content, selected_invoices
        # content => [first_half,second_half]
        [email_type, customer_id, receive_address, content, selected_invoices, email_cc, email_bcc]
    end

    def get_invoice_table(customer_id, monthly, date)
        invoice = XeroContact.where(skype_user_name: customer_id).first
        return nil if invoice.nil?
        invoice = invoice.xero_invoices.has_amount_due
        invoice = invoice.period_select(@end_date) unless @end_date.nil?
        date =	Date.strptime(date.to_s, '%Y-%m-%d')
        sum_of_amount = {}
        sum_of_amount['invoice_date'] = Array.new(6) { 0 }
        sum_of_amount['due_date'] = Array.new(6) { 0 }
        invoice.each do |i|
            interval = ('monthly'.eql? monthly) ? ((date.year * 12 + date.month) - (i.date.to_date.year * 12 + i.date.to_date.month)) : ((date.mjd - i.date.to_date.mjd) / 15)
            interval = interval > 5 ? 5 : interval
            sum_of_amount['invoice_date'][interval] += i.amount_due
            interval = ('monthly'.eql? monthly) ? ((date.year * 12 + date.month) - (i.due_date.to_date.year * 12 + i.due_date.to_date.month)) : ((date.mjd - i.due_date.to_date.mjd) / 15)
            interval = interval < 0 ? 0 : interval
            interval = interval > 5 ? 5 : interval
            sum_of_amount['due_date'][interval] += i.amount_due
        end

        sum_of_amount
    end

    def get_email_content(params, staff_id, customer_id, selected_invoices, cn_op)
        # form builder
        email_content = AccountEmail.new
        email_content.send_address = Staff.find(staff_id).email
        email_content.receive_address = @checked_send_email_to_self ? email_content.send_address : @xero_contact.email
        email_content.email_type = params[:commit]
        unless @checked_send_email_to_self
            # luke_email = Staff.find(9).email
            staff = Staff.find Staff.find(Customer.find(customer_id).staff_id).report_to
            # email_content.cc = luke_email +";"+staff.email.to_s
            lucia_email = Staff.find(25).email
            email_content.cc = lucia_email +";"+staff.email.to_s
        end
        # set default_email_content, this function is located in helpers-> accounts_helper
        email_content.content, email_content.content_second, @email_title = default_email_content(params[:commit], cn_op)
        email_content.customer_id = customer_id
        email_content.selected_invoices = selected_invoices

        email_content
    end
end
