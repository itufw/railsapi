require 'xero_connection.rb'
require 'clean_data.rb'

class XeroInvoice < ActiveRecord::Base
	self.primary_key = 'xero_invoice_id'

	belongs_to :xero_contact
	has_many :xero_over_payment_allocations
	has_many :xero_invoice_line_items
	has_many :xero_credit_note_allocations

	def scrape

		xero = XeroConnection.new.connect
  		clean = CleanData.new

  		page_num = 1
		
		invoices = xero.Invoice.all(page: page_num)

		until invoices.blank?

			invoices.each do |i|

				date = clean.map_date(i.date.to_s)
	  			due_date = clean.map_date(i.due_date.to_s)
	  			updated_date = clean.map_date(i.updated_date_utc.to_s)

	  	 		contact_name = clean.remove_apostrophe(i.contact_name) unless i.contact_name.nil?

	  			if order_id.nil?
	  				order_id = 0
	  			end
	  			
	  			time = Time.now.to_s(:db)

	  			if XeroInvoice.where(xero_invoice_id: i.invoice_id).count == 0

		  			sql = "INSERT INTO xero_invoices (xero_invoice_id, xero_invoice_number,\
		  			xero_contact_id, xero_contact_name, sub_total, total, total_tax, amount_due,\
		  			amount_paid, amount_credited, date, due_date, date_modified, status, line_amount_types,
		  			type, created_at, updated_at) VALUES ('#{i.invoice_id}', '#{i.invoice_number}',\
		  			'#{i.contact_id}', '#{contact_name}', '#{i.sub_total}', '#{i.total}',\
		  			'#{i.total_tax}', '#{i.amount_due}', '#{i.amount_paid}', '#{i.amount_credited}',\
		  			'#{date}','#{due_date}', '#{updated_date}', '#{i.status}', '#{i.line_amount_types}',\
		  			'#{i.type}', '#{time}', '#{time}')"

		  			ActiveRecord::Base.connection.execute(sql)

		  			XeroInvoiceLineItem.new.scrape(i.line_items, i.invoice_id)
		  		end
	  		end

	  		page_num += 1

	  		invoices = xero.Invoice.all(page: page_num)

  		end

	end
end
