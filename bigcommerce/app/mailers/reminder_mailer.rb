class ReminderMailer < ActionMailer::Base
  require 'mail'
  require 'wicked_pdf'

  default from: 'it@untappedwines.com'
  layout "mailer"

  def send_overdue_reminder(customer_id, template)
    @xero_contact = XeroContact.where(:skype_user_name => customer_id).first
    @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(:xero_contact_id => @xero_contact.xero_contact_id).order(:due_date)
    @template = template

    customer_address = %("#{@xero_contact.name}" <it@untappedwines.com>)

    case template
    when "overdue"
      email_subject = "OVERDUE REMINDER – Untapped Fine Wines – #{@xero_contact.name}"
      attach_invoices(@over_due_invoices)
    when "overdue_60days"
      email_subject = "OVERDUE PAYMENT REQUIRED – Untapped Fine Wines – #{@xero_contact.name}"
      attach_invoices(@over_due_invoices)
    when "overdue_90days"
      email_subject = "FINAL NOTICE PAYMENT REQUIRED, 90+ Days Overdue – Untapped Fine Wines – #{@xero_contact.name}"
      attach_invoices(@over_due_invoices)
    when "new_order_hold"
      email_subject = "ORDER ON HOLD – Untapped Fine Wines – #{@xero_contact.name}"
      attach_invoices(@over_due_invoices)
    end
    mail(from: 'it@untappedwine.com',to: customer_address, subject: email_subject)
  end


  def statement_generator(customer_id)
    xero_contact = XeroContact.where(:skype_user_name => customer_id).first
    over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(:xero_contact_id => xero_contact.xero_contact_id).order(:due_date)

    attachments["Overdue Invoices.pdf"] = WickedPdf.new.pdf_from_string(
    render_to_string(
        :template => 'pdf/overdue_invoice',
        :locals => {:over_due_invoices => over_due_invoices,
                    :contact => xero_contact}
        )
    )
  end


  # input is an array with selected invoices model
  def attach_invoices(selected_invoices)
    selected_invoices.includes(:xero_contact, :xero_invoice_line_items, :order)
    # attach the selected invoices for customer
    selected_invoices.each do |invoice|
      bill_address = Address.where(id: invoice.invoice_number).count == 0 ? "missing" : Address.find(invoice.invoice_number)
      order = Order.includes(:order_products).where("orders.id = '#{invoice.invoice_number}'").count == 0 ? "missing" : Order.find("#{invoice.invoice_number}")
      customer_notes = ((("missing".eql? order)==true) || ("".eql? order.customer_notes)) ? "missing" : order.customer_notes

      # The Customer Type!
      # cust_type_id: 1.Retail, 2. Wholesale, 3. Staff
      if 2 == Customer.where("customers.xero_contact_id = '#{invoice.xero_contact_id}'").first.cust_type_id
        attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(
              :template => 'pdf/pdf_invoice',
              :locals => {:invoice => invoice,
                          :bill_address => bill_address,
                          :customer_notes => customer_notes,
                          :order => order}
              )
        )
      else
        attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(
            :template => 'pdf/pdf_invoice_retail',
            :locals => { :invoice => invoice,
                         :bill_address => bill_address,
                         :customer_notes => customer_notes,
                         :order => order})
        )
      end
    end
  end

  # input is an array with selected invoices number
  def attach_invoices_number(selected_invoices)
    # attach the selected invoices for customer
    selected_invoices.each do |i|
      invoice = XeroInvoice.includes(:xero_contact, :xero_invoice_line_items, :order).where("xero_invoices.invoice_number = #{i}").first
      bill_address = Address.where(id: invoice.invoice_number).count == 0 ? "missing" : Address.find(invoice.invoice_number)
      order = Order.includes(:order_products).where("orders.id = '#{invoice.invoice_number}'").count == 0 ? "missing" : Order.find("#{invoice.invoice_number}")
      customer_notes = ((("missing".eql? order)==true) || ("".eql? order.customer_notes)) ? "missing" : order.customer_notes

      # The Customer Type!
      # cust_type_id: 1.Retail, 2. Wholesale, 3. Staff
      if 2 == Customer.where("customers.xero_contact_id = '#{invoice.xero_contact_id}'").first.cust_type_id
        attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(
              :template => 'pdf/pdf_invoice',
              :locals => {:invoice => invoice,
                          :bill_address => bill_address,
                          :customer_notes => customer_notes,
                          :order => order}
              )
        )
      else
        attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(
            :template => 'pdf/pdf_invoice_retail',
            :locals => { :invoice => invoice,
                         :bill_address => bill_address,
                         :customer_notes => customer_notes,
                         :order => order})
        )
      end
    end
  end

  def reminder_email(customer_id,selected_invoices)

    @customer = Customer.include_all.filter_by_id(customer_id)
    @xero_contact = @customer.xero_contact
    @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where("invoice_number IN (?)",selected_invoices).order(:due_date)

    attach_invoices_number(selected_invoices)

    email_subject = "MISSING INVOICE PAYMENT – Untapped Fine Wines – #{@customer.xero_contact.name}"

    customer_address = %("#{@customer.xero_contact.name}" <it@untappedwines.com>)
    mail(from: 'it@untappedwine.com',to: customer_address, subject: email_subject)
  end
end
