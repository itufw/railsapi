class ReminderMailer < ActionMailer::Base
  require 'mail'
  require 'wicked_pdf'
  require 'order_status.rb'
  require 'stock_control.rb'

  include OrderStatus
  include StockControl

  default from: 'accounts@untappedwines.com'
  layout "mailer"

  def error_warning(error_class, error_message, backtrace)
    @error_class = error_class
    @error_message = error_message
    @backtrace = backtrace.join("\n")
    mail(from: 'Untapped IT <it@untappedwines.com>', to: 'William Liu <it@untappedwines.com>', cc: 'Luke Voortman <lvoortman@untappedwines.com>', subject: "Sync Error")
  end

  def stock_control_reminder
    xlsx = render_to_string formats: [:xlsx], template: "admin/export_stock_control", locals: {countries: ProducerCountry.product_country, product_hash: stock_calculation(), portfolio_list: portfolio_products()}
    attachments["Stock Control #{Date.today.to_s}.xlsx"] = {mime_type: Mime::XLSX, content: Base64.encode64(xlsx), encoding: 'base64'}

    # sales = []
    # sales.push(%("SalesTeam" <salesteam@untappedwines.com>))
    # sales.push(%("Paola <paola@untappedwines.com>"))
    #
    # managers = []
    # managers.push(%("Adam" <adam@untappedwines.com>))
    # managers.push(%("Angelica" <accounts@untappedwines.com>))
    # managers.push(%("Luke" <lvoortman@untappedwines.com>))
    # managers.push(%("Lucia" <lgaldona@untappedwines.com>))

    mail(from: 'Untapped CMS <it@untappedwines.com>', to: ['Lucia <lgaldona@untappedwines.com>', 'SalesTeam <salesteam@untappedwines.com>'], bcc: 'William Liu <it@untappedwines.com>', subject: "Stock Control #{Date.today.to_s}")

    # mail(from: 'Untapped CMS <it@untappedwines.com>', to: sales, cc: managers, bcc: 'William Liu <it@untappedwines.com>', subject: "Stock Control #{Date.today.to_s}")
  end

  def order_confirmation(order_id, email_address, user_id)
    @order = Order.find(order_id)
    @customer = @order.customer
    @staff = @order.staff

    customer_address = %("#{@customer.actual_name}" <#{email_address}>)
    subject = "Untapped Fine Wines Order #{@order.id} – #{@customer.actual_name}"
    attachments["Invoice##{order_id}.pdf"] = print_single_invoice(@order)

    mail(from: "Untapped Fine Wines <accounts@untappedwines.com>", to: customer_address, bcc: @staff.email + ";" + Staff.find(user_id).email, reply_to: @staff.email, subject: subject)
  end

  def send_overdue_reminder(customer_id, email_subject,staff_id,email_content,email_address, cc, bcc, email_type, selected_invoices, cn_op, attachment_tmp)
    @cn_op = ("{}".eql? cn_op) ? {} : unzip_cn_op_hash(cn_op)
    @total_remaining_credit = (@cn_op.map {|x| x[:remaining_credit]}).sum
    staff = Staff.find(staff_id)
    staff_name = staff.firstname + " " + staff.lastname
    @xero_contact = XeroContact.where(:skype_user_name => customer_id).first

    if ["Send Reminder", "Send Missed Payment"].include? email_type
      @over_due_invoices = XeroInvoice.has_amount_due.where("invoice_number IN (?)",selected_invoices).order(:due_date)
      @missing_invoice = true
    else
      @over_due_invoices = XeroInvoice.has_amount_due.over_due_invoices.where(:xero_contact_id => @xero_contact.xero_contact_id).order(:due_date)
      @missing_invoice = false
    end

    attach_invoices(@over_due_invoices)
    attach_credit_note(@cn_op, @over_due_invoices.map {|x| x.xero_invoice_id}, @xero_contact.name)


    # attachment file
    # basically Pod
    unless attachment_tmp.nil? || attachment_tmp.blank?
      attachment_tmp.each do |attachment_tmp_file|
        attachment_tmp_path = File.absolute_path(attachment_tmp_file.tempfile)
        attachment_tmp_name = attachment_tmp_file.original_filename
        attachments[attachment_tmp_name] = File.read(attachment_tmp_path)
      end
    end

    @email_content = email_content
    recipients_addresses = []
    email_address.split(";").each do |contact_address|
      customer_address = %("#{@xero_contact.name}" <#{contact_address}>)
      recipients_addresses.push(customer_address)
    end
    bcc_group = []
    bcc.split(";").each do |contact_address|
      customer_address = %(#{contact_address})
      bcc_group.push(customer_address)
    end
    bcc_group.push(%("#{staff_name}" <#{staff.email}>))

    cc_group = []
    cc.split(";").each do |contact_address|
      customer_address = %(#{contact_address})
      cc_group.push(customer_address)
    end

    record_email(recipients_addresses, staff.email, email_type, cc_group, bcc_group, email_content.first, email_content.last, customer_id, @over_due_invoices.map {|x| x.invoice_number}, staff_id)


    # customer_address = %("#{@xero_contact.name}" <#{email_address}>)
    mail(from: "\"#{staff_name}\" <accounts@untappedwines.com>",to: recipients_addresses, cc: cc_group, bcc: bcc_group, subject: email_subject)
  end

  def unzip_cn_op_hash(cn_op_list)
    cn_op = []
    cn_op_list.split("} {").each do |co|
      co = "{" + co unless "{".eql? co.first
      co = co + "}" unless "}".eql? co.last
      cn_op.push(eval(co))
    end
    cn_op
  end

  def record_email(receive_address, send_address, email_type, cc, bcc, content, content_second, customer_id, selected_invoices, staff_id)

    email_content = AccountEmail.new

    email_content.receive_address = receive_address
    email_content.send_address = send_address
    email_content.email_type = email_type
    email_content.cc = cc
    email_content.bcc = bcc
    email_content.content = content
    email_content.content_second = content_second
    email_content.customer_id = customer_id
    email_content.selected_invoices = selected_invoices

    email_content.save!
    Task.new.auto_insert_from_mailer(email_type, customer_id, staff_id, email_content.id, selected_invoices)

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
        # attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
        #   render_to_string(
        #       :template => 'pdf/pdf_invoice',
        #       :locals => {:invoice => invoice,
        #                   :bill_address => bill_address,
        #                   :customer_notes => customer_notes,
        #                   :order => order}
        #       )
        # )
        attachments["invoice\##{invoice.invoice_number}.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(
              :template => 'pdf/order_invoice.pdf',
              :locals => {order: order, customer: order.customer}
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

      pod = FastwayTrace.pod_available(invoice.invoice_number).first
      if !pod.nil?
        item = FastwayConsignmentItem.filter_order(invoice.invoice_number).first
        attachments["#{invoice.invoice_number}-pod.pdf"] = WickedPdf.new.pdf_from_string(
          render_to_string(
              :template => 'pdf/proof_of_delivery.pdf',
              :locals => {order: Order.find(invoice.invoice_number), item: item }
              )
          )
      elsif !order.proof_of_delivery.file.nil?
        attachments[order.proof_of_delivery.file.filename.to_s] = open(order.proof_of_delivery.to_s).read
      end
    end
  end

  def attach_credit_note(cn_op, invoice_ids, xero_contact_name)
    credit_note_numbers = []
    # include the selected credit note
    cn_op.each do |co|
      credit_note_numbers.push(co[:status]) if co[:status].start_with?("CN")
    end

    # credit note that applied on the invoices
    credit_note_numbers.push(*(XeroCnAllocation.apply_to_invoices(invoice_ids).map {|x| x.credit_note_number}))
    credit_note_numbers = credit_note_numbers.uniq

    if credit_note_numbers.blank?
      return
    end

    credit_note_numbers.each do |cn_number|
      credit_note = XeroCreditNote.where("xero_credit_notes.credit_note_number = '#{cn_number}'").first
      cn_line_items = XeroCNLineItem.where("xero_cn_line_items.xero_credit_note_id = '#{credit_note.xero_credit_note_id}'")
      cn_allocations = XeroCnAllocation.apply_from_credit_note_number(cn_number)

      latest_invoice_number = XeroInvoice.find(invoice_ids.first).invoice_number
      bill_address = (Address.where(id: latest_invoice_number).count == 0) ? "missing" : Address.find(latest_invoice_number)


      attachments["Credit Note \##{cn_number}.pdf"] = WickedPdf.new.pdf_from_string(
        render_to_string(
            :template => 'pdf/credit_note',
            :locals => {:credit_note => credit_note,
                        :cn_line_items => cn_line_items,
                        :cn_allocations => cn_allocations,
                        :bill_address => bill_address,
                        :xero_contact_name => xero_contact_name
                        }
            )
      )
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

end
