require 'rake_task_helper.rb'

include RakeTaskHelper

namespace :updates do
	desc "Rake task to update data"
	task :models => :environment do

		if can_start_update

			Revision.start_update
			start_time = Time.now

			puts "Models update #{start_time} started"

			admin = AdminController.new

			admin.update_customers
			puts "Updated Customers"

			admin.update_products
			puts "Updated Products"

			admin.update_orders
			puts "Updated Orders"

			xero = XeroController.new

			xero.update_xero_contacts
			puts "Updated Xero Contacts"

			xero.update_xero_invoices
			puts "Updated Xero Invoices"

			Revision.end_update(start_time, Time.now)

			puts "Models update #{Time.now} ended"

		end
	end

	task :timeperiods => :environment do
	  	puts "Staff Time Periods Update #{Time.now} started"
	  	StaffTimePeriod.new.update_all
	  	puts "Staff Time Periods Update #{Time.now} ended"

			puts "Update contacts balance #{Time.now} started"
			XeroContact.new.update_balance_for_all
			puts "Update contacts balance #{Time.now} ended"
	end

	task :balanceupdate => :environment do
		puts "Update contacts balance #{Time.now} started"
		XeroContact.new.update_balance_for_all
		puts "Update contacts balance #{Time.now} ended"
	end

end
