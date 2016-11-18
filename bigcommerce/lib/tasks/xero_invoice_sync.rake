require 'rake_task_helper.rb'

include RakeTaskHelper

namespace :xero_invoice_sync do
	task :sync => :environment do

		if can_start_xero_sync

			start_time = Time.now

			XeroRevision.start_update

			puts "Xero Sync #{start_time} started"

			XeroController.new.link_bigc_xero_orders
			puts "Xero Invoices are linked to Orders"

			XeroController.new.export_invoices_to_xero
			puts "Invoices are exported"
			puts "Xero Sync #{Time.now} ended"

			XeroRevision.end_update(start_time, Time.now)
		end
	end
end