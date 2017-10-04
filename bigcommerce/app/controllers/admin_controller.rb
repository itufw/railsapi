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
        send_data export_orders(params[:status],Date.parse(params[:date][:start_date]), Date.parse(params[:date][:end_date])), filename: "orders-#{Date.parse(params[:date][:end_date])}.csv" and return
      when 'Shipment'
        send_data export_shipment(Date.parse(params[:date][:start_date]), Date.parse(params[:date][:end_date])), filename: "ship-#{Date.parse(params[:date][:end_date])}.csv" and return
      when 'ScotPac'
        send_data export_orders(12, (Date.today - 8.years), Date.today), filename: "ScotPac-#{Date.parse(params[:date][:end_date])}.csv" and return
      end
      redirect_to :back
    end

    def download_stock_control
      pdf = WickedPdf.new.pdf_from_string(
        render_to_string(
            :template => 'pdf/stock_control.pdf',
            :locals => {countries: ProducerCountry.product_country }
            )
        )
        send_data pdf, filename: "StockControl-#{Date.today.to_s}.pdf", type: :pdf
    end

    def export_stock_control
      @countries = ProducerCountry.product_country
      product_hash = {}
      products_no_ws = ProductNoWs.joins(:products)
       .select('product_no_ws.*, products.case_size as case_size, products.calculated_price AS price, products.retail_ws AS retail_ws, products.name as product_name, products.inventory as inventory, products.id as product_id, products.name_no_winery as name_no_winery')

      allocated_products = OrderProduct.joins(:order).select('product_id, SUM(order_products.qty) as qty').where('orders.status_id': 1).group('product_id')

      products_no_ws.each do |p|
        # Separate Perth Stock
        next if p.product_name.include?'Perth'

        # initialise the hash
        product = (product_hash[p.id].nil?) ? {inventory: 0, allocated: 0} : product_hash[p.id]

        product[:name] = p.name_no_winery unless p.name_no_winery.nil?
        product[:inventory] += p.inventory
        product[:case_size] = p.case_size

        allocated = allocated_products.detect{|x| x.product_id==p.product_id}
        product[:allocated] += allocated.qty unless allocated.nil?

        if p.retail_ws=='R'
          product[:rrp] = p.price * 1.1
        elsif p.product_name.include?'WS'
          product[:ws_id] = p.product_id
          product[:luc] = p.price * 1.29
        end

        product_hash[p.id] = product
      end

      # Include Only In Stock Products
      @product_hash = product_hash.select{|key, value| value[:inventory]>0 }

      respond_to do |format|
        format.html
        format.xlsx
      end
    end

    def group_list
      group_creation(params) unless params[:staff_group].nil?
      default_group_update(params) unless params[:default_group].nil?

      params = {}
      @groups = StaffGroup.staff_groups(session[:user_id])
    end

    def group_creation(params)
      if params[:staff_group][:group_name].to_s == ""
        flash[:error] = 'Group must have a name!'
      elsif StaffGroup.duplicated(session[:user_id], params[:staff_group][:group_name]).blank?
        StaffGroup.new({group_name: params[:staff_group][:group_name], staff_id: session[:user_id]}).save
        flash[:success] = 'Group Created!'
      else
        flash[:error] = 'Duplicated Group Name!'
      end
    end

    def default_group_update(params)
      session[:default_group] = params[:default_group]
    end

    def fetch_group_detail
      @group = StaffGroup.where(id: params[:group_id]).first
      respond_to do |format|
        format.js
      end
    end

    def fetch_add_item
      StaffGroupItem.new(staff_group_id: params[:group_id], item_model: params[:item_model], item_id: params[:item_id]).save
      respond_to do |format|
        format.js
      end
    end

    def fetch_remove_item
      StaffGroupItem.where(staff_group_id: params[:group_id], item_model: params[:item_model], item_id: params[:item_id]).delete_all
      respond_to do |format|
        format.js
      end
    end
end
