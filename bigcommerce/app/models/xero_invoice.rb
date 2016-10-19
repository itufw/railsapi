require 'xero_connection.rb'
require 'clean_data.rb'

class XeroInvoice < ActiveRecord::Base

	include CleanData

	self.primary_key = 'xero_invoice_id'

	belongs_to :order
	belongs_to :xero_contact
	has_many :xero_invoice_line_items
	has_many :xero_payments

	has_many :xero_cn_allocations
	has_many :xero_op_allocations

	def download_data_from_api(modified_since_time)

		xero = XeroConnection.new.connect

  		page_num = 1
		
		invoices = xero.Invoice.all(page: page_num, modified_since: modified_since_time)

		until invoices.blank?

			invoices.each do |i|

				date = map_date(i.date)
	  			due_date = map_date(i.due_date)
	  			updated_date = map_date(i.updated_date_utc)
	  			fully_paid_on_date = map_date(i.fully_paid_on_date)
	  			expected_payment_date = map_date(i.expected_payment_date)

	  	 		contact_name = remove_apostrophe(i.contact_name)
	  	 		url = remove_apostrophe(i.url)
	  	 		reference = remove_apostrophe(i.reference)

	  	 		sent_to_contact = convert_bool(i.sent_to_contact)
	  	 		has_attachments = convert_bool(i.has_attachments)

	  			
	  			time = Time.now.to_s(:db)

	  			if valid_invoice(i)

	  		# 		if invoice_doesnt_exist(i.invoice_id)

	  		# 			sql = "INSERT INTO xero_invoices (xero_invoice_id, invoice_number,\
					# 	xero_contact_id, contact_name, sub_total, total_tax, total, total_discount,\
					# 	amount_due, amount_paid, amount_credited, date, due_date, fully_paid_on_date,\
					# 	expected_payment_date, updated_date, status, line_amount_types, invoice_type,\
					# 	currency_code, currency_rate, url, reference, branding_theme_id, sent_to_contact,\
					# 	has_attachments, created_at, updated_at)\
					# 	VALUES ('#{i.invoice_id}', '#{i.invoice_number}',\
					# 	'#{i.contact_id}', '#{contact_name}', '#{i.sub_total(true)}', '#{i.total_tax(true)}',\
					# 	'#{i.total(true)}', '#{i.total_discount}', '#{i.amount_due}', '#{i.amount_paid}',\
					# 	'#{i.amount_credited}', '#{date}', '#{due_date}', '#{fully_paid_on_date}',\
					# 	'#{expected_payment_date}', '#{updated_date}', '#{i.status}', '#{i.line_amount_types}',\
					# 	'#{i.type}', '#{i.currency_code}', '#{i.currency_rate}',\
					# 	'#{url}', '#{reference}', '#{i.branding_theme_id}', '#{sent_to_contact}',\
					# 	'#{has_attachments}', '#{time}', '#{time}')"
					# 	ActiveRecord::Base.connection.execute(sql)

					# else

					# 	# sql = "UPDATE xero_invoices SET invoice_number = '#{i.invoice_number}',\
					# 	# xero_contact_id = '#{i.contact_id}', contact_name = '#{contact_name}',\
					# 	# sub_total = '#{i.sub_total(true)}', total_tax = '#{i.total_tax(true)}',\
					# 	# total = '#{i.total(true)}', total_discount = '#{i.total_discount}',\
					# 	# amount_due = '#{i.amount_due}', amount_paid = '#{i.amount_paid}',\
					# 	# amount_credited = '#{i.amount_credited}', date = '#{date}', due_date = '#{due_date}',\
					# 	# fully_paid_on_date = '#{fully_paid_on_date}', expected_payment_date = '#{expected_payment_date}',\
					# 	# updated_date = '#{updated_date}', status = '#{i.status}',\
					# 	# line_amount_types = '#{i.line_amount_types}', invoice_type = '#{i.type}',\
					# 	# currency_code = '#{i.currency_code}', currency_rate = '#{i.currency_rate}',\
					# 	# url = '#{url}', reference = '#{i.reference}', branding_theme_id = '#{i.branding_theme_id}',\
					# 	# sent_to_contact = '#{sent_to_contact}', has_attachments = '#{has_attachments}', updated_at = '#{time}'\
					# 	# WHERE xero_invoice_id = '#{i.invoice_id}'"

					# end
					XeroInvoiceLineItem.new.download_data_from_api(i.line_items, i.invoice_id, i.invoice_number)


	  				# ActiveRecord::Base.connection.execute(sql)

		  			# XeroInvoiceLineItem.new.download_data_from_api(i.line_items, i.invoice_id, i.invoice_number)
		  		end
	  		end

	  		puts "Page Num : " + page_num.to_s

	  		page_num += 1

	  		invoices = xero.Invoice.all(page: page_num, modified_since: modified_since_time)

  		end

	end

	def valid_invoice(invoice)
		if invoice.status == 'DELETED' || invoice.status == 'VOIDED' || invoice.type != 'ACCREC'
			return false
	    else
	    	return true
	    end
	end

	def invoice_doesnt_exist(invoice_id)
        if XeroInvoice.where(xero_invoice_id: invoice_id).count == 0
  			return true
  		else
  			return false
  	    end
  	end

  	def self.get_invoice_id_and_number(invoice_number)
  		if where(invoice_number: invoice_number).count > 0
  			invoice = where(invoice_number: invoice_number).first
  			return invoice
  		else
  			return false
  		end
  	end

  	def self.find_by_order_id(order_id)
  		if invoice = XeroInvoice.get_invoice_id_and_number(order_id.to_s)
  			return invoice
  		elsif invoice = XeroInvoice.get_invoice_id_and_number('BC' + order_id.to_s)
  			return invoice
  		else
  			return nil
  		end
  	end

  	def self.create_in_xero(contact, order, sub_total, total_tax)
  		xero = XeroConnection.new.connect
  		invoice = xero.Invoice.build(invoice_number: order.id.to_s, contact: contact,\
  			type: 'ACCREC', date: order.date_created.to_date, due_date: 30.days.since(order.date_created.to_date),\
  			line_amount_types: 'INCLUSIVE', amount_due: order.total_inc_tax,\
  			amount_paid: 0.0, amount_credited: 0.0, sent_to_contact: false,\
  			has_attachments: false, total: order.total_inc_tax, sub_total: sub_total,\
  			total_tax: total_tax)
  		return invoice
  	end

end
