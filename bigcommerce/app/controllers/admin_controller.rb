require 'csv_import.rb'

class AdminController < ApplicationController
    before_action :confirm_logged_in

    # CustType
    # CustGroup
    # CustStore
    # Staff

    # Address - scrape - Shipping Address
    # Coupon - scrape - also from inside order

    # def initialize
    #   @update_time = nil
    #   @start_time = nil

    # end

    def index; end

    # def scrape

    #   Revision.new.insert

    #   models_scrape = [Category.new, Product.new, Customer.new, Status.new, Order.new]

    #   models_scrape.each do |m|
    #     m.scrape
    #   end

    #   csv_import

    #   @success = "Yay!"

    # end

    def update; end

    def update_products
        Product.new.update_from_api(Revision.update_time_iso)
    end

    def update_customers
        Customer.new.update_from_api(Revision.update_time_iso)
    end

    def update_orders
        Order.new.update_from_api(Revision.update_time_iso)
    end

    def import_from_csv
        # product_files = [[ProducerCountry, "producer_countries", nil], [Producer, "producers", nil],\
        # [ProducerRegion, "producer_regions", nil], [ProductType, "product_types", nil],\
        # [ProductSubType, "product_sub_types", nil], [ProductSize, "product_sizes", nil],\
        # [ProductPackageType, "product_package_types", nil],[Warehouse, "warehouses", nil]]

        # product_files.each do |p|

        # CSVImport.new.do(Product, "products" , "current", "display")
        # CSVImport.new.do(ProducerRegion, 'producer_regions')
        # CSVImport.new.do(ProductSubType, 'product_subtype')
        # CSVImport.new.do(Producer, 'producers')
        # CSVImport.new.do(ProductNoWs, 'Prod_no_ws')
        # CSVImport.new.do(ProductNoVintage, 'product_novintage')
        # CSVImport.new.do(Product, 'products')
        # CSVImport.new.do(Order, 'OrderAdjustPleaseWill')
        # CSVImport.new.do(Customer, 'customers')

        # end

        # render 'update'
    end

    # models_csv_import = [CustGroup.new, CustStyle.new, CustType.new, Customer.new]

    # models_scrape.each do |m|
    # m.csv_import
    # end

    def xero_sync
        XeroRevision.update_end_time(Time.now.utc)
        xero = XeroController.new
        xero.update_xero_contacts
        xero.update_xero_invoices

        system 'rake xero_invoice_sync:sync'
        flash[:success] = 'Sync is Done!'
        redirect_to controller: 'admin', action: 'index'
    end

    def staff_update; end

    def password_update
        if params[:username].present? && params[:password].present?
            found_user = Staff.where(logon_details: params[:username]).first
            if found_user
                authorized_user = found_user.authenticate(params[:password])
            end
        end
        if authorized_user && (params[:new_password].eql? params[:new_password_confirmation])
            found_user.password_digest = BCrypt::Password.create(params[:new_password])
            found_user.save!
            flash[:success] = 'Updated.'
        elsif authorized_user
            flash[:error] = 'new password confirmation failed'
        else
            flash[:error] = 'Invalid username/password combination'
        end
        redirect_to action: 'staff_update'
    end
end
