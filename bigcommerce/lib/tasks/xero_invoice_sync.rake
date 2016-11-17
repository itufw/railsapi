require 'rake_task_helper.rb'

include RakeTaskHelper

namespace :xero_invoice_sync do
	task :sync => :environment do

		if can_start_xero_sync

			XeroRevision.start_update(Time.now)

			puts "Xero Sync #{Time.now} started"

			XeroController.new.link_bigc_xero_orders
			puts "Xero Invoices are linked to Orders"

			XeroController.new.export_invoices_to_xero
			puts "Invoices are exported"
			puts "Xero Sync #{Time.now} ended"

			XeroRevision.end_update(start_time)
		end
	end
end