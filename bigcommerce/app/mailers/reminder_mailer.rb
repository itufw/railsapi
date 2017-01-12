class ReminderMailer < ActionMailer::Base
  require 'mail'
  default from: 'it@untappedwines.com'
  layout "mailer"

  def reminder_email(customer_id,selected_invoices)
    @customer = Customer.include_all.filter_by_id(customer_id)

    @selected_invoices = selected_invoices

    # attach the invoice file -> the path of the pdf template may be changed
    # the blow works as well
    #     pdf = WickedPdf.new.pdf_from_string(
    #   render_to_string('templates/pdf', layout: 'pdfs/layout_pdf.html'),
    #   footer: {
    #     content: render_to_string(
    #         'templates/footer',
    #         layout: 'pdfs/layout_pdf.html'
    #     )
    #   }
    # )
    attachments["invoice.pdf"] = WickedPdf.new.pdf_from_string(
      render_to_string(:pdf => "accounts",:template => 'accounts/pdf_invoice.pdf.erb')
    )

    customer_address = %("#{@customer.xero_contact.name}" <it@untappedwines.com>)
    # the one that worked
    mail(from: 'it@untappedwine.com',to: customer_address, subject: 'new testing', body: 'hello from other side')
  end
end
