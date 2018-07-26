require 'rake_task_helper.rb'
load 'zomato_calculation.rb'
load 'fastway_api.rb'
require 'google_calendar_sync.rb'
load 'stock_control.rb'

include RakeTaskHelper
include ZomatoCalculation
include GoogleCalendarSync
include FastwayApi
include StockControl

namespace :updates do
	desc "Rake task to update data"
	task :models => :environment do

		if can_start_update
			begin
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
			rescue Exception => ex
				ReminderMailer.error_warning(ex.class, ex.message, ex.backtrace).deliver_now if Revision.bigcommerce.attempt_count == 2
			end

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
		search_by_zomato
		puts "Zomato Update End #{Time.now}"
	end

	task :event_update => :environment do
		start_time = Time.now
		Revision.google.start_update

		puts "Event Update Start At #{start_time}"
		begin
			import_into_customer_tags
			calendar_event_update(Revision.google.start_time, StaffCalendarAddress.where(sync_calendar: 1))

			puts "Event Update End AT #{Time.now}"
			Revision.google.end_update(start_time, Time.now)
		rescue Exception => ex
			ReminderMailer.error_warning(ex.class, ex.message, ex.backtrace).deliver_now
		end
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

	task :wake_signatures => :environment do
		puts 'Wake Signatures Up'
		wake_signatures
		puts 'Waked Signature'
	end

	task :sales_rate_update => :environment do
		puts 'Sales Rate Update Start'
		sales_rate_update
		puts 'Sales Rate Update End'
	end

	task :send_stock_control => :environment do
		ReminderMailer.stock_control_reminder.deliver_now
	end

	task :send_sale_report => :environment do
		ReminderMailer.send_sale_report.deliver_now
	end
	
	task :balanceupdate => :environment do
		puts "Update contacts balance #{Time.now} started"
		XeroContact.new.update_balance_for_all
		puts "Update contacts balance #{Time.now} ended"
	end

end
