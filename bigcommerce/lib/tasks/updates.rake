namespace :updates do
	desc "Rake task to update data"
	task :cron => :environment do
	  admin = AdminController.new
	  admin.update_products
	  puts "Updated Products"
	  admin.update_customers
	  puts "Updated Customers"
	  admin.update_orders
	  puts "Updated Orders"
	end
end