require 'rake_task_helper.rb'

include RakeTaskHelper

namespace :xero_invoice_sync do
	task :sync => :environment do
		if can_start_xero_sync
			begin

					start_time = Time.now

					Revision.xero.start_update

					puts "Xero Sync #{start_time} started"

					XeroController.new.link_bigc_xero_orders
					puts "Xero Invoices are linked to Orders"

					XeroController.new.export_invoices_to_xero
					puts "Invoices are exported"
					puts "Xero Sync #{Time.now} ended"

					Revision.xero.end_update(start_time, Time.now)
			rescue Exception => ex
				puts "An error of type #{ex.class} happened, message is #{ex.message}"
				ReminderMailer.error_warning(ex.class, ex.message).deliver_now
			end
		end

	end
end
