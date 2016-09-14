require 'xero_connection.rb'
require 'clean_data.rb'

class XeroInvoice < ActiveRecord::Base
	self.primary_key = 'xero_invoice_id'

	belongs_to :xero_contact
	has_many :xero_over_payment_allocations
	has_many :xero_invoice_line_items
	has_many :xero_credit_note_allocations
	has_many :xero_payments

	def scrape

		xero = XeroConnection.new.connect
  		clean = CleanData.new

  		page_num = 1
		
		invoices = xero.Invoice.all(page: page_num)

		until invoices.blank?

			invoices.each do |i|

				date = clean.map_date(i.date)
	  			due_date = clean.map_date(i.due_date)
	  			updated_date = clean.map_date(i.updated_date_utc)
	  			fully_paid_on_date = clean.map_date(i.fully_paid_on_date)
	  			expected_payment_date = clean.map_date(i.expected_payment_date)

	  	 		contact_name = clean.remove_apostrophe(i.contact_name) unless i.contact_name.nil?

	  			
	  			time = Time.now.to_s(:db)

	  			if valid_invoice(i) && invoice_doesnt_exist(i.invoice_id)

		  			sql = "INSERT INTO xero_invoices (xero_invoice_id, xero_invoice_number,\
		  			xero_contact_id, xero_contact_name, sub_total, total_tax, total, amount_due,\
		  			amount_paid, amount_credited, total_discount, date, due_date, fully_paid_on_date, expected_payment_date,\
		  			updated_date, status, line_amount_types, type, reference, currency_code, currency_rate,\
		  			created_at, updated_at)\
		  			VALUES ('#{i.invoice_id}', '#{i.invoice_number}',\
		  			'#{i.contact_id}', '#{contact_name}', '#{i.sub_total(true)}', '#{i.total_tax(true)}',\
		  			'#{i.total(true)}', '#{i.amount_due}', '#{i.amount_paid}', '#{i.amount_credited}', '#{i.total_discount}',\
		  			'#{date}', '#{due_date}', '#{fully_paid_on_date}', '#{expected_payment_date}',\
		  			'#{updated_date}', '#{i.status}', '#{i.line_amount_types}',\
		  			'#{i.type}', '#{i.reference}', '#{i.currency_code}', '#{i.currency_rate}', '#{time}', '#{time}')"

		  			ActiveRecord::Base.connection.execute(sql)

		  			XeroInvoiceLineItem.new.scrape(i.line_items, i.invoice_id)
		  		end
	  		end

	  		page_num += 1

	  		invoices = xero.Invoice.all(page: page_num)

  		end

	end

	def valid_invoice(invoice)
		if invoice.status != 'DELETED' && invoice.type == 'ACCREC'
			return true
	    else
	    	return false
	    end
	end

	def invoice_doesnt_exist(invoice_id)
        if XeroInvoice.where(xero_invoice_id: invoice_id).count == 0
  			return true
  		else
  			return false
  	    end
  	end

end
