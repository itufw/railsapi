require 'uuid_helper.rb'
require 'xero_connection.rb'
require 'clean_data.rb'

class XeroInvoice < ActiveRecord::Base
	include UUIDHelper

  	#belongs_to :order
  	belongs_to :xero_contact, foreign_key: :contact_id

  	self.primary_key = 'invoice_id'

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

	  			order_id = i.invoice_number.gsub("BC","") unless i.invoice_number.nil?
	  			
	  			time = Time.now.to_s(:db)

	  			if XeroInvoice.where(invoice_id: i.invoice_id).count == 0

		  			sql = "INSERT INTO xero_invoices (invoice_id, order_id, contact_id, contact_name, total,\
		  			sub_total, total_tax, amount_due, amount_paid, amount_credited, date, due_date,\
		  			updated_date, status, type, has_attachments, created_at, updated_at) VALUES ('#{i.invoice_id}',\
		  			'#{order_id}', '#{i.contact_id}', '#{contact_name}', '#{i.total}', '#{i.sub_total}',\
		  			'#{i.total_tax}', '#{i.amount_due}', '#{i.amount_paid}', '#{i.amount_credited}', '#{date}',\
		  			'#{due_date}', '#{updated_date}', '#{i.status}', '#{i.type}', '#{i.has_attachments}',\
		  			'#{time}', '#{time}')"

		  			ActiveRecord::Base.connection.execute(sql)
		  		end
	  		end

	  		page_num += 1

	  		invoices = xero.Invoice.all(page: page_num)

  		end

  	end

end
