require 'csv_import.rb'

class AdminController < ApplicationController

  before_action :confirm_logged_in

  # CustType
  # CustGroup
  # CustStore
  # Staff

  # Address - scrape - Shipping Address
  # Coupon - scrape - also from inside order

  def index
  end

  def scrape

    Revision.new.insert

    models_scrape = [Category.new, Product.new, Customer.new, Status.new, Order.new]

    models_scrape.each do |m|
      m.scrape
    end

    csv_import

    @success = "Yay!"

  end

  def update
    @update_time = Revision.order("created_at").last.next_update_time.iso8601
    #update_time = "2016-07-18T00:00:00Z"
    Time.zone = "GMT"
    start_time = Time.current
    update_products
    #models_update = [Customer.new, Order.new]

    # models_update.each do |m|
    #    m.update(update_time)
    # end
    Revision.new.insert("", start_time)
  end

  def update_products
    Product.new.update_from_api(@update_time)
  end

  def update_customers
    Customer.new.update_from_api(@update_time)
  end

  def update_orders
    Order.new.update_from_api(@update_time)
  end

  def import_from_csv


    # product_files = [[ProducerCountry, "producer_countries", nil], [Producer, "producers", nil],\
    # [ProducerRegion, "producer_regions", nil], [ProductType, "product_types", nil],\
    # [ProductSubType, "product_sub_types", nil], [ProductSize, "product_sizes", nil],\
    # [ProductPackageType, "product_package_types", nil],[Warehouse, "warehouses", nil]]


     

    #product_files.each do |p|

          CSVImport.new.do(Product, "product_ref" , "current", "display")
          CSVImport.new.do(ProductNoVintage, "product_no_vintage" , nil)

    #end

    render 'update'

  end

    #models_csv_import = [CustGroup.new, CustStyle.new, CustType.new, Customer.new]

    #models_scrape.each do |m|
      #m.csv_import
    #end

end
