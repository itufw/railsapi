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
	  start_time = Time.now
	  puts "Time Periods Update #{start_time} started"
	  StaffTimePeriod.new.update_all
	  puts "Time Periods Update #{Time.now} ended"
	end
end