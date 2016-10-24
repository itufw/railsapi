namespace :updates do
	desc "Rake task to update data"
	task :models => :environment do
	  start_time = Time.now
	  puts "Models update #{start_time} started"
	  admin = AdminController.new
	  admin.update_products
	  puts "Updated Products"
	  admin.update_customers
	  puts "Updated Customers"
	  admin.update_orders
	  puts "Updated Orders"
	  Revision.new.insert("", start_time)
	  puts "Models update #{Time.now} ended"
	end

	task :timeperiods => :environment do
	  puts "Staff Time Periods Update #{Time.now} started"
	  StaffTimePeriod.new.update_all
	  puts "Staff Time Periods Update #{Time.now} ended"
	end

	task :xero_sync => :environment do
	  puts "Xero Sync #{Time.now} started"
	  XeroController.new.update_xero_invoices
	  XeroController.new.link_bigc_xero_orders
	  XeroController.new.export_invoices_to_xero
	  puts "Xero Sync #{Time.now} ended"
	end
end