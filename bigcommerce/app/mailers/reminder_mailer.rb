class ReminderMailer < ActionMailer::Base
  require 'mail'
  require 'wicked_pdf'

  default from: 'it@untappedwines.com'
  layout "mailer"

  def reminder_email(customer_id,selected_invoices)
    @customer = Customer.include_all.filter_by_id(customer_id)

    @selected_invoices = selected_invoices

    @selected_invoices.each do |i|
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
            #  :footer =>{:html => {
            #                       :template => 'pdf/footer.html.erb',
            #                     },
            #             :spacing => -65}
              )
        )
      else
        attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(:template => 'pdf/pdf_invoice_retail', :locals => { :invoice => invoice, :bill_address => bill_address, :customer_notes => customer_notes, :order => order})
        )
      end
    end

    customer_address = %("#{@customer.xero_contact.name}" <it@untappedwines.com>)
    # the one that worked
    mail(from: 'it@untappedwine.com',to: customer_address, subject: 'new testing', body: 'hello from other side')
  end
end
