module AccountsHelper
    include ActionView::Helpers::NumberHelper

    def date_column_checked(date_column)
        if 'due_date'.eql? date_column
            # @checked_due_date = true
            # @checked_invoice_date = false
            return true, false
        end
        [false, true]
    end

    def monthly_checked(monthly)
        if 'monthly'.eql? monthly
            # @checked_due_date = true
            # @checked_invoice_date = false
            return true, false
        end
        [false, true]
    end

    def email_preview(email_ratio)
        return false, true if 'no'.eql? email_ratio
        [true, false]
    end

    def default_email_content(commit)
        email_content = ''
        content_second_half = ''
        email_title = ''
        case commit
        when 'Send Reminder', 'Send Missed Payment'
            email_content = "Hi,<br><br>
                            Thanks for the recent payment that was made to our account.<br><br>
                            Could I please refer you to an invoice that has been missed that we’re still awaiting payment for. The details are below.<br><br>"
            content_second_half = "I’ve attached a copy of the invoice(s) in case you are missing them in your records. I will also follow-up with an additional email providing the Proof of delivery (POD).<br><br>
                                  Thanks for the help and if you have any questions please be in contact.<br><br>"
            email_title = "MISSING INVOICE PAYMENT – Untapped Fine Wines – #{@customer_name}"

        when 'Send Overdue Reminder'
            email_content = "Hi,<br><br>
                            We have outstanding balance for wine that was delivered for <b>#{@customer_name}</b> total <span class=\"wysiwyg-color-red\">#{number_to_currency(@over_due_invoices.sum(:amount_due))}</span>. Please see the details below."
            content_second_half = "This balance is now <a style=\"color: red\">overdue</a> and we require payment of the amount provided above and repeated in the attached statement in order to continue to provide credit terms on a regular basis.<br><br>
                                  Can you please examine this and either give me a call or reply to this email as to when the outstanding amount can be settled.<br><br>
                                  I’ve attached a copy of the invoice(s) in case you are missing them in your records.<br><br>
                                  If you have any questions regarding your account please be in contact.<br><br>
                                  We appreciate your help in having this paid promptly."
            email_title = "OVERDUE REMINDER – Untapped Fine Wines – #{@customer_name}"

        when 'Send 60 Days Overdue Reminder'
            email_content = "Hi,<br><br>
                            We have outstanding balance of <span class=\"wysiwyg-color-red\">#{number_to_currency(@over_due_invoices.sum(:amount_due))} </span> for <b>#{@customer_name}</b>. Please see the details below.<br><br>
                            Until this overdue amount is settled any new order must be paid for prior to being dispatched<br><br>"
            content_second_half = "If you have any questions regarding your account please be in contact.<br><br>
                                  Attached are copies of the invoice(s) listed above in case they are missing from your records.<br><br>
                                  We appreciate your help in having this paid promptly.<br><br>"
            email_title = "OVERDUE PAYMENT REQUIRED – Untapped Fine Wines – #{@customer_name}"

        when 'Send 90 Days Overdue Reminder'
            email_content = "Hi,<br><br>
                            We have outstanding balance of <span class=\"wysiwyg-color-red\">#{number_to_currency(@over_due_invoices.sum(:amount_due))}</span> for <b>#{@customer_name}</b>. Some of this wine is more than 90 days overdue. The details are listed below.
                            We cannot continue to provide credit terms for your account on a normal basis. Until any overdue amount is cleared all new invoice must be paid for on creation before they can be shipped.
                            We have made repeated attempts to address this outstanding amount with you and now we require immediate payment.<br><br>"
            content_second_half = "Please be in contact with myself or our Operations and Finance manager Luke Voortman on 03 9676 9663 to discuss when we can expect to receive payment. If we fail to receive contact from you across the coming week we will begin <b>recovery actions </b>. Any costs relating to recovery actions will be passed on to your business. Please be aware that these recovery costs can be costly.<br><br>
                                  Attached are copies of the invoice(s) listed above in case they are missing from your records.<br><br>
                                  We appreciate your help and in responding to this quickly.<br><br>"
            email_title = "FINAL NOTICE PAYMENT REQUIRED, 90+ Days Overdue – Untapped Fine Wines – #{@customer_name}"

        when 'Send New Order Hold'
            email_content = "Hi,<br><br>
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
        invoice = XeroContact.where(skype_user_name: customer_id).first.xero_invoices.has_amount_due.period_select(@end_date)
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

    def record_email(account_email)


      email_content = AccountEmail.new

      email_content.receive_address = account_email.receive_address
      email_content.email_type = account_email.email_type
      email_content.cc = account_email.cc
      email_content.bcc = account_email.bcc
      email_content.content = account_email.content
      email_content.content_second = account_email.content_second
      email_content.customer_id = account_email.customer_id
      email_content.selected_invoices = account_email.selected_invoices
      
      email_content.save!
    end
end
