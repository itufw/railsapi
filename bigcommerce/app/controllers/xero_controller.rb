require 'xero_controller_helper.rb'
require 'xero_invoice_calculations.rb'

class XeroController < ApplicationController

	include XeroControllerHelper
	include XeroInvoiceCalculations

	def link_bigc_xero_contact
		Customer.xero_contact_id_is_null.each {|c| link_skype_id(c.id)}
		#Customer.xero_contact_id_is_null.each {|c| link_skype_id_by_customer_name(c.id, c.actual_name)}
	end

	def link_bigc_xero_orders
		Order.export_to_xero.each {|o| link_invoice_id(o.id)}
		#Order.where('xero_invoice_id IS NULL').each {|o| link_invoice_id(o.id)}
	end

	def update_xero_invoices
		XeroInvoice.new.download_data_from_api(Revision.update_time)
	end

	def update_xero_contacts
		XeroContact.new.download_data_from_api(Revision.update_time.2.days.ago)
	end

	def export_invoices_to_xero
		xero_sync
	end

end
