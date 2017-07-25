require 'rake_task_helper.rb'
load 'zomato_calculation.rb'
load 'fastway_api.rb'
require 'google_calendar_sync.rb'

include RakeTaskHelper
include ZomatoCalculation
include GoogleCalendarSync
include FastwayApi

namespace :updates do
	desc "Rake task to update data"
	task :models => :environment do

		if can_start_update

			Revision.bigcommerce.start_update
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

			Revision.bigcommerce.end_update(start_time, Time.now)

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

	task :zomato_update => :environment do
		puts "Zomato Update At #{Time.now}"
		search_by_geo
	end

	task :event_update => :environment do
		start_time = Time.now
		Revision.google.start_update

		puts "Event Update Start At #{start_time}"
		import_into_customer_tags
		calendar_event_update(Revision.google.start_time)
		puts "Event Update End AT #{Time.now}"
		Revision.google.end_update(start_time, Time.now)
	end

	task :manifest_update => :environment do
		puts "Manifest Update Start At #{Time.now}"
		update_closed_manifest
		puts "Manifest Update End AT #{Time.now}"
	end

	task :package_trace => :environment do
		puts "Shipping Update Start At #{Time.now}"
		trace_events
		puts "Shipping Update End At #{Time.now}"
	end

	task :balanceupdate => :environment do
		puts "Update contacts balance #{Time.now} started"
		XeroContact.new.update_balance_for_all
		puts "Update contacts balance #{Time.now} ended"
	end

end
