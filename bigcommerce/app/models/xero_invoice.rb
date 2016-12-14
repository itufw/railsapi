require 'xero_connection.rb'
require 'clean_data.rb'
require 'dates_helper.rb'

class XeroInvoice < ActiveRecord::Base

	include CleanData
	include DatesHelper

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

	  	 		if line_amount_types == "Inclusive"
	  	 			calculate_line_amount = true
	  	 		else
	  	 			calculate_line_amount = false
	  	 		end

	  			
	  			time = Time.now.to_s(:db)

	  			if valid_invoice(i)

	  				if invoice_doesnt_exist(i.invoice_id)

	  					sql = "INSERT INTO xero_invoices (xero_invoice_id, invoice_number,\
						xero_contact_id, contact_name, sub_total, total_tax, total, total_discount,\
						amount_due, amount_paid, amount_credited, date, due_date, fully_paid_on_date,\
						expected_payment_date, updated_date, status, line_amount_types, invoice_type,\
						currency_code, currency_rate, url, reference, branding_theme_id, sent_to_contact,\
						has_attachments, created_at, updated_at)\
						VALUES ('#{i.invoice_id}', '#{i.invoice_number}',\
						'#{i.contact_id}', '#{contact_name}', '#{i.sub_total(calculate_line_amount)}', '#{i.total_tax(calculate_line_amount)}',\
						'#{i.total(calculate_line_amount)}', '#{i.total_discount}', '#{i.amount_due}', '#{i.amount_paid}',\
						'#{i.amount_credited}', '#{date}', '#{due_date}', '#{fully_paid_on_date}',\
						'#{expected_payment_date}', '#{updated_date}', '#{i.status}', '#{i.line_amount_types}',\
						'#{i.type}', '#{i.currency_code}', '#{i.currency_rate}',\
						'#{url}', '#{reference}', '#{i.branding_theme_id}', '#{sent_to_contact}',\
						'#{has_attachments}', '#{time}', '#{time}')"

					else

						sql = "UPDATE xero_invoices SET invoice_number = '#{i.invoice_number}',\
						xero_contact_id = '#{i.contact_id}', contact_name = '#{contact_name}',\
						sub_total = '#{i.sub_total(calculate_line_amount)}', total_tax = '#{i.total_tax(calculate_line_amount)}',\
						total = '#{i.total(calculate_line_amount)}', total_discount = '#{i.total_discount}',\
						amount_due = '#{i.amount_due}', amount_paid = '#{i.amount_paid}',\
						amount_credited = '#{i.amount_credited}', date = '#{date}', due_date = '#{due_date}',\
						fully_paid_on_date = '#{fully_paid_on_date}', expected_payment_date = '#{expected_payment_date}',\
						updated_date = '#{updated_date}', status = '#{i.status}',\
						line_amount_types = '#{i.line_amount_types}', invoice_type = '#{i.type}',\
						currency_code = '#{i.currency_code}', currency_rate = '#{i.currency_rate}',\
						url = '#{url}', reference = '#{i.reference}', branding_theme_id = '#{i.branding_theme_id}',\
						sent_to_contact = '#{sent_to_contact}', has_attachments = '#{has_attachments}', updated_at = '#{time}'\
						WHERE xero_invoice_id = '#{i.invoice_id}'"

					end

	  				ActiveRecord::Base.connection.execute(sql)

		  			XeroInvoiceLineItem.new.download_data_from_api(i.line_items, i.invoice_id, i.invoice_number)
		  		end
	  		end

	  		page_num += 1

	  		invoices = xero.Invoice.all(page: page_num, modified_since: modified_since_time)

  		end

	end

	def valid_invoice(invoice)
		if (invoice.type != 'ACCREC')
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

  	def self.get_invoice_id_for_valid_invoice(invoice_number)
  		invoice = where("invoice_number = '#{invoice_number}' and (status = 'PAID' or status = 'AUTHORISED')")
  		if invoice.count == 1
  			return invoice.first.xero_invoice_id
  		else
  			return false
  		end
  
  	end
  		
  	def self.find_by_order_id(order_id)
  		if invoice_id = XeroInvoice.get_invoice_id_for_valid_invoice(order_id.to_s)
  			return invoice_id
  		elsif invoice = XeroInvoice.get_invoice_id_for_valid_invoice('BC' + order_id.to_s)
  		 	return invoice
  		else
  			return nil
  		end
  	end

  	def self.filter_by_invoice_number(invoice_number)
  		invoice = where(invoice_number: invoice_number.to_s)
  		if invoice.empty?
  			return nil
  		else
  			return invoice.first
  		end
  	end

  	def self.is_submitted(order_id)
  		return where(invoice_number: order_id.to_s, status: "SUBMITTED").count == 1
  	end

  	def self.paid(xero_invoice)
  		if xero_invoice && xero_invoice.status == 'PAID'
  			return ["PAID", xero_invoice.amount_due]
  		end
  	end

  	def self.unpaid(xero_invoice)
  		if xero_invoice && xero_invoice.status == 'AUTHORISED' && xero_invoice.amount_due > 0 && xero_invoice.amount_paid == 0
  			return ["UNPAID", invoice.first.amount_due]
  		end
  	end

  	def self.partially_paid(xero_invoice)
  		if xero_invoice && xero_invoice.status == 'AUTHORISED' && xero_invoice.amount_paid > 0\
  		 	&& xero_invoice.amount_paid < xero_invoice.amount_due
  			return ["PARTIALLY-PAID", invoice.first.amount_due]
  		end
  	end

end
