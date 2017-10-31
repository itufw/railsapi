module CsvGenerator
  def export_to_csv(objects)
    return if objects.blank?
    attributes = objects.first.attributes.keys
    CSV.generate(headers: true) do |csv|
      csv << attributes

      objects.each do |line|
        csv << attributes.map { |attr| line.send(attr) }
      end
    end
  end

  def excel_customer(_start_date, _end_date)
    sql = 'customers.id AS  "Customer ID", firstname AS  "First Name", lastname AS  "Last Name", company AS  "Company", email AS  "Email", phone AS "Phone", note AS  "Notes", store_credit AS  "Store Credit", name AS  "Customer Group", date_created AS  "Date Joined", address AS "Address", description AS  "Required"'
    customers = Customer.joins(:cust_style).select(sql)
    customers
  end

  def excel_order(bigc_status, start_date, end_date)
    sql = 'orders.id AS "Order ID", customer_id AS "Customer ID", actual_name AS "Customer Name",
     customers.email AS "Customer Email", "" AS "Customer Phone", Date(orders.date_created) AS "Order Date",
    statuses.bigcommerce_name AS "Order Status", "" AS "Subtotal(inc-Tax)", "" AS "Subtotal(ex-Tax)",
    "" AS "Tax Total", ROUND(shipping_cost, 2) AS "Shipping Cost", "" AS "Shipping Cost(ex tax)",
    "" AS "Ship Method", "" AS "Handling Cost", ROUND(orders.total_inc_tax, 2) AS "Order Total",
    "" AS "Order Total(ex tax)", staffs.nickname AS "Payment Method", orders.qty AS "Total Quantity",
    orders.items_shipped AS "Total Shipped", Date(orders.date_shipped) AS "Date Shipped"'

    if bigc_status == ''
      orders = Order.joins(:staff, :customer, :status).select(sql)
                    .where("orders.date_created > '#{start_date}' AND orders.date_created < '#{end_date}'")
                    .order('orders.id DESC')
    else
      orders = Order.joins(:staff, :customer, :status).select(sql)
                    .where('statuses.bigcommerce_id = ?', bigc_status.to_i)
                    .where("orders.date_created > '#{start_date}' AND orders.date_created < '#{end_date}'")
                    .order('orders.id DESC')
    end
    orders
  end

  def excel_shipping(start_date, end_date)
    sql = ' "" AS "Shipment ID", Date(date_shipped) AS "Date Shipped", orders.id AS "ORDER ID",
      Date(orders.date_created) AS "Order Date", track_number AS "Tracking No",
      courier_statuses.description AS "Shipping Method"'
    orders = Order.joins(:courier_status, :status)
                  .select(sql).where('statuses.in_transit = 1 OR statuses.delivered = 1')
                  .where("orders.date_created > '#{start_date}' AND orders.date_created < '#{end_date}'")
                  .order('orders.id DESC')
    orders
  end

  def excel_receivables
    contacts = XeroContact.outstanding_is_greater_zero.order(:name)
    contacts
  end

  def export_customer(start_date, end_date)
    customers = excel_customer(start_date, end_date)

    attributes = customers.first.attributes.keys
    attributes.delete('id')

    CSV.generate(headers: true) do |csv|
      csv << attributes

      customers.each do |line|
        csv << attributes.map { |attr| line.send(attr) }
      end
    end
  end

  def export_order_products(start_date, end_date)
    sql = '"" as "Co./Last Name", "" as "First Name",	"" as "Address Line 1",
     ""	as "Address Line 2", ""	as "Address Line 3", "" as "Address Line 4",
    orders.id as "Invoice#", Date(orders.date_created) as "Date", "" as "Ship via",
    product_id as "Item Number", order_products.qty as "Quantity",
    name as "Description", ROUND(price_luc,2) as "Inc-Tax Price",
    ROUND(orders.total_inc_tax - orders.discount_amount * 1.1 - orders.shipping_cost * 1.1,2) as "Total",
    ROUND(orders.total_inc_tax, 2) as "Inc-Tax Total", "" as "Comment", "" as "Shipping Date",
    "" as "Tax Amount", ""	as "Inc-Tax Freight Amount", ""	as "Currency Code",
    "" as "Exchange Rate", "" as "Payment Method",	"" as "Payment Notes", orders.customer_id as "Card ID"'

    order_products = OrderProduct.joins(:order, :product).select(sql).where("orders.date_created > '#{start_date}' AND orders.date_created < '#{end_date}'")
    attributes = order_products.first.attributes.keys
    attributes.delete('id')

    CSV.generate(headers: true) do |csv|
      csv << attributes

      order_products.each do |line|
        csv << attributes.map { |attr| line.send(attr) }
      end
    end
  end

  def export_orders(bigc_status, start_date, end_date)
    orders = excel_order(bigc_status, start_date, end_date)

    attributes = orders.first.attributes.keys
    attributes.delete('id')
    CSV.generate(headers: true) do |csv|
      csv << attributes

      orders.each do |line|
        csv << attributes.map { |attr| line.send(attr) }
      end
    end
  end

  def ship_info_update
    Order.where('id > 23000').each do |order|
      fastways = FastwayConsignmentItem.where('LabelNumber IS NOT NULL').where("Reference LIKE '#{order.id}'")
      next if fastways.blank?
      sql = "UPDATE orders SET track_number = '#{fastways.map(&:LabelNumber).join(';')}', courier_status_id = 4 Where id = #{order.id}"
      ActiveRecord::Base.connection.execute(sql)
    end
  end

  def export_shipment(start_date, end_date)
    orders = excel_shipping(start_date, end_date)

    attributes = orders.first.attributes.keys
    attributes.delete('id')

    CSV.generate(headers: true) do |csv|
      csv << attributes

      orders.each do |line|
        csv << attributes.map { |attr| line.send(attr) }
      end
    end
  end

  def export_products(start_date, end_date); end
end
