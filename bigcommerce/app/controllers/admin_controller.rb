require 'csv_import.rb'
require 'csv_generator.rb'


class AdminController < ApplicationController
    before_action :confirm_logged_in

    include CsvGenerator


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

    def index;end

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
        Product.new.update_from_api(Revision.bigcommerce.update_time_iso)
    end

    def update_customers
        Customer.new.update_from_api(Revision.bigcommerce.update_time_iso)
    end

    def update_orders
        BigcommerceOrder.new.update_from_api(Revision.bigcommerce.update_time_iso)
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
        start_time = Time.now.utc
        Revision.xero.update_end_time
        xero = XeroController.new
        xero.update_xero_contacts
        xero.update_xero_invoices

        system 'rake xero_invoice_sync:sync'
        flash[:success] = 'Sync is Done!'
        Revision.xero.end_update(start_time, Time.now)
        redirect_to controller: 'admin', action: 'index'
    end


    def xero_sync_temp
        Revision.xero.update_end_time(Time.now.utc)

        system 'rake xero_invoice_sync:sync'
        flash[:success] = 'Sync is Done! (Temporary!)'
        redirect_to controller: 'admin', action: 'index'
    end


    def password_update
        current_user = Staff.find(session[:user_id])
        if current_user.can_update
            if params[:staff].present? && params[:staff][:id].present?
                staff_to_update = Staff.find(params[:staff][:id])
                if params[:new_password].eql? params[:new_password_confirmation]
                    staff_to_update.password_digest = BCrypt::Password.create(params[:new_password])
                    staff_to_update.save!
                    flash[:success] = 'Updated'
                else
                    flash[:error] = 'Passwords don\'t match'
                end
            else
                flash[:error] = 'Select a Staff to Update'
            end
        else
            flash[:error] = 'Not authorised to update'
        end
        redirect_to action: 'index'
    end

    def admin;end

    def password_update_user
      current_user = Staff.find(session[:user_id])
      if current_user.can_update
          if params[:staff].present? && params[:staff][:id].present?
              staff_to_update = Staff.find(params[:staff][:id])
              if params[:new_password].eql? params[:new_password_confirmation]
                  staff_to_update.password_digest = BCrypt::Password.create(params[:new_password])
                  staff_to_update.save!
                  flash[:success] = 'Updated'
              else
                  flash[:error] = 'Passwords don\'t match'
              end
          else
              flash[:error] = 'Select a Staff to Update'
          end
      else
          flash[:error] = 'Not authorised to update'
      end
      redirect_to action: 'admin'
    end

    def staff_order_update
      redirect_to action: 'index'
    end

    def download_csv
      case params[:commit]
      when 'Customer'
        send_data export_customer(Date.parse(params[:date][:start_date]), Date.parse(params[:date][:end_date])), filename: "customer-#{Date.parse(params[:date][:end_date])}.csv" and return
      when 'Order Products'
        send_data export_order_products(Date.parse(params[:date][:start_date]), Date.parse(params[:date][:end_date])), filename: "order-products-#{Date.parse(params[:date][:end_date])}.csv" and return
      when 'Orders'
        send_data export_orders(Date.parse(params[:date][:start_date]), Date.parse(params[:date][:end_date])), filename: "orders-#{Date.parse(params[:date][:end_date])}.csv" and return
      when 'Shippment'
        send_data export_shippment(Date.parse(params[:date][:start_date]), Date.parse(params[:date][:end_date])), filename: "ship-#{Date.parse(params[:date][:end_date])}.csv" and return
      end
      redirect_to :back
    end
end
