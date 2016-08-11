namespace :updates do
	desc "Rake task to update data"
	task :cron => :environment do
	  start_time = Time.now
	  puts "#{start_time} started"
	  admin = AdminController.new
	  admin.update_products
	  puts "Updated Products"
	  admin.update_customers
	  puts "Updated Customers"
	  admin.update_orders
	  puts "Updated Orders"
	  Revision.new.insert("", start_time)
	  puts "#{Time.now} ended"
	end
end