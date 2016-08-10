# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160729025219) do

  create_table "addresses", force: :cascade do |t|
    t.integer  "customer_id", limit: 4
    t.text     "firstname",   limit: 255
    t.text     "lastname",    limit: 255
    t.text     "company",     limit: 255
    t.text     "street_1",    limit: 65535
    t.text     "street_2",    limit: 65535
    t.text     "city",        limit: 255
    t.text     "state",       limit: 255
    t.text     "postcode",    limit: 255
    t.text     "country",     limit: 255
    t.text     "phone",       limit: 255
    t.text     "email",       limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "addresses", ["customer_id"], name: "index_addresses_on_customer_id", using: :btree

  create_table "categories", force: :cascade do |t|
    t.integer  "parent_id",        limit: 4
    t.text     "name",             limit: 255
    t.text     "description",      limit: 65535
    t.integer  "visible",          limit: 1
    t.integer  "sort_order",       limit: 4
    t.text     "page_title",       limit: 65535
    t.text     "meta_keywords",    limit: 65535
    t.text     "meta_description", limit: 65535
    t.text     "search_keywords",  limit: 65535
    t.text     "url",              limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "categories", ["parent_id"], name: "index_categories_on_parent_id", using: :btree

  create_table "coupons", force: :cascade do |t|
    t.text     "name",       limit: 255, null: false
    t.text     "code",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "cust_groups", force: :cascade do |t|
    t.text     "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "cust_styles", force: :cascade do |t|
    t.text     "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "cust_types", force: :cascade do |t|
    t.text     "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "customers", force: :cascade do |t|
    t.text     "firstname",               limit: 255
    t.text     "lastname",                limit: 255
    t.text     "company",                 limit: 255
    t.text     "email",                   limit: 255
    t.text     "phone",                   limit: 255
    t.text     "actual_name",             limit: 65535
    t.integer  "staff_id",                limit: 4
    t.integer  "cust_type_id",            limit: 4
    t.integer  "cust_group_id",           limit: 4
    t.integer  "cust_store_id",           limit: 4
    t.datetime "date_created"
    t.datetime "date_modified"
    t.decimal  "store_credit",                          precision: 20, scale: 2
    t.text     "registration_ip_address", limit: 255
    t.text     "notes",                   limit: 65535
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "cust_style_id",           limit: 4
    t.string   "region",                  limit: 255
  end

  add_index "customers", ["cust_group_id"], name: "index_customers_on_cust_group_id", using: :btree
  add_index "customers", ["cust_store_id"], name: "index_customers_on_cust_store_id", using: :btree
  add_index "customers", ["cust_type_id"], name: "index_customers_on_cust_type_id", using: :btree
  add_index "customers", ["staff_id"], name: "index_customers_on_staff_id", using: :btree

  create_table "default_average_periods", force: :cascade do |t|
    t.integer  "staff_id",   limit: 4
    t.string   "name",       limit: 255
    t.integer  "days",       limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "default_start_dates", force: :cascade do |t|
    t.integer  "staff_id",     limit: 4
    t.date     "default_date"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "order_histories", force: :cascade do |t|
    t.integer  "order_id",                   limit: 4,                              null: false
    t.datetime "date_created"
    t.integer  "customer_id",                limit: 4,                              null: false
    t.integer  "status_id",                  limit: 4,                              null: false
    t.integer  "staff_id",                   limit: 4
    t.decimal  "total_inc_tax",                            precision: 20, scale: 2
    t.decimal  "refunded_amount",                          precision: 20, scale: 2
    t.integer  "qty",                        limit: 3,                              null: false
    t.integer  "items_shipped",              limit: 3
    t.text     "staff_notes",                limit: 65535
    t.text     "customer_notes",             limit: 65535
    t.integer  "billing_address_id",         limit: 4
    t.integer  "coupon_id",                  limit: 4
    t.text     "payment_method",             limit: 255
    t.decimal  "discount_amount",                          precision: 20, scale: 2
    t.decimal  "coupon_discount",                          precision: 20, scale: 2
    t.decimal  "subtotal_ex_tax",                          precision: 20, scale: 2
    t.decimal  "subtotal_inc_tax",                         precision: 20, scale: 2
    t.decimal  "subtotal_tax",                             precision: 20, scale: 2
    t.decimal  "total_ex_tax",                             precision: 20, scale: 2
    t.decimal  "total_tax",                                precision: 20, scale: 2
    t.decimal  "base_shipping_cost",                       precision: 20, scale: 2
    t.decimal  "shipping_cost_ex_tax",                     precision: 20, scale: 2
    t.decimal  "shipping_cost_inc_tax",                    precision: 20, scale: 2
    t.decimal  "shipping_cost_tax",                        precision: 20, scale: 2
    t.decimal  "base_handling_cost",                       precision: 20, scale: 2
    t.decimal  "handling_cost_ex_tax",                     precision: 20, scale: 2
    t.decimal  "handling_cost_inc_tax",                    precision: 20, scale: 2
    t.decimal  "handling_cost_tax",                        precision: 20, scale: 2
    t.decimal  "base_wrapping_cost",                       precision: 20, scale: 2
    t.decimal  "wrapping_cost_ex_tax",                     precision: 20, scale: 2
    t.decimal  "wrapping_cost_inc_tax",                    precision: 20, scale: 2
    t.decimal  "wrapping_cost_tax",                        precision: 20, scale: 2
    t.decimal  "store_credit",                             precision: 20, scale: 2
    t.decimal  "gift_certificate_amount",                  precision: 20, scale: 2
    t.integer  "shipping_cost_tax_class_id", limit: 4
    t.integer  "handling_cost_tax_class_id", limit: 4
    t.integer  "wrapping_cost_tax_class_id", limit: 4
    t.integer  "active",                     limit: 1
    t.text     "ip_address",                 limit: 65535
    t.text     "order_source",               limit: 255
    t.datetime "date_modified"
    t.datetime "date_shipped"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
  end

  add_index "order_histories", ["billing_address_id"], name: "index_order_histories_on_billing_address_id", using: :btree
  add_index "order_histories", ["coupon_id"], name: "index_order_histories_on_coupon_id", using: :btree
  add_index "order_histories", ["customer_id"], name: "index_order_histories_on_customer_id", using: :btree
  add_index "order_histories", ["order_id"], name: "index_order_histories_on_order_id", using: :btree
  add_index "order_histories", ["staff_id"], name: "index_order_histories_on_staff_id", using: :btree
  add_index "order_histories", ["status_id"], name: "index_order_histories_on_status_id", using: :btree

  create_table "order_product_histories", force: :cascade do |t|
    t.integer  "order_history_id",  limit: 4,                          null: false
    t.integer  "order_id",          limit: 4,                          null: false
    t.integer  "product_id",        limit: 4,                          null: false
    t.integer  "order_shipping_id", limit: 4,                          null: false
    t.integer  "qty",               limit: 3,                          null: false
    t.integer  "qty_shipped",       limit: 3,                          null: false
    t.decimal  "base_price",                  precision: 20, scale: 2, null: false
    t.decimal  "price_ex_tax",                precision: 20, scale: 2, null: false
    t.decimal  "price_inc_tax",               precision: 20, scale: 2, null: false
    t.decimal  "price_tax",                   precision: 20, scale: 2, null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
  end

  add_index "order_product_histories", ["order_history_id"], name: "index_order_product_histories_on_order_history_id", using: :btree
  add_index "order_product_histories", ["order_id"], name: "index_order_product_histories_on_order_id", using: :btree
  add_index "order_product_histories", ["order_shipping_id"], name: "index_order_product_histories_on_order_shipping_id", using: :btree
  add_index "order_product_histories", ["product_id"], name: "index_order_product_histories_on_product_id", using: :btree

  create_table "order_products", force: :cascade do |t|
    t.integer  "order_id",          limit: 4,                          null: false
    t.integer  "product_id",        limit: 4,                          null: false
    t.integer  "order_shipping_id", limit: 4,                          null: false
    t.integer  "qty",               limit: 3,                          null: false
    t.integer  "qty_shipped",       limit: 3,                          null: false
    t.decimal  "base_price",                  precision: 20, scale: 2, null: false
    t.decimal  "price_ex_tax",                precision: 20, scale: 2, null: false
    t.decimal  "price_inc_tax",               precision: 20, scale: 2, null: false
    t.decimal  "price_tax",                   precision: 20, scale: 2, null: false
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
  end

  add_index "order_products", ["order_id"], name: "index_order_products_on_order_id", using: :btree
  add_index "order_products", ["order_shipping_id"], name: "index_order_products_on_order_shipping_id", using: :btree
  add_index "order_products", ["product_id"], name: "index_order_products_on_product_id", using: :btree

  create_table "order_shipping_histories", force: :cascade do |t|
    t.integer  "order_history_id", limit: 4, null: false
    t.integer  "address_id",       limit: 4, null: false
    t.integer  "items_total",      limit: 4
    t.integer  "items_shipped",    limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "order_shipping_histories", ["address_id"], name: "index_order_shipping_histories_on_address_id", using: :btree
  add_index "order_shipping_histories", ["order_history_id"], name: "index_order_shipping_histories_on_order_history_id", using: :btree

  create_table "order_shippings", force: :cascade do |t|
    t.integer  "order_id",      limit: 4, null: false
    t.integer  "address_id",    limit: 4, null: false
    t.integer  "items_total",   limit: 4
    t.integer  "items_shipped", limit: 4
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "order_shippings", ["address_id"], name: "index_order_shippings_on_address_id", using: :btree
  add_index "order_shippings", ["order_id"], name: "index_order_shippings_on_order_id", using: :btree

  create_table "orders", force: :cascade do |t|
    t.datetime "date_created"
    t.integer  "customer_id",                limit: 4,                              null: false
    t.integer  "status_id",                  limit: 4
    t.integer  "staff_id",                   limit: 4
    t.decimal  "total_inc_tax",                            precision: 20, scale: 2
    t.decimal  "refunded_amount",                          precision: 20, scale: 2
    t.integer  "qty",                        limit: 3,                              null: false
    t.integer  "items_shipped",              limit: 3
    t.text     "staff_notes",                limit: 65535
    t.text     "customer_notes",             limit: 65535
    t.integer  "billing_address_id",         limit: 4
    t.integer  "coupon_id",                  limit: 4
    t.text     "payment_method",             limit: 255
    t.decimal  "discount_amount",                          precision: 20, scale: 2
    t.decimal  "coupon_discount",                          precision: 20, scale: 2
    t.decimal  "subtotal_ex_tax",                          precision: 20, scale: 2
    t.decimal  "subtotal_inc_tax",                         precision: 20, scale: 2
    t.decimal  "subtotal_tax",                             precision: 20, scale: 2
    t.decimal  "total_ex_tax",                             precision: 20, scale: 2
    t.decimal  "total_tax",                                precision: 20, scale: 2
    t.decimal  "base_shipping_cost",                       precision: 20, scale: 2
    t.decimal  "shipping_cost_ex_tax",                     precision: 20, scale: 2
    t.decimal  "shipping_cost_inc_tax",                    precision: 20, scale: 2
    t.decimal  "shipping_cost_tax",                        precision: 20, scale: 2
    t.decimal  "base_handling_cost",                       precision: 20, scale: 2
    t.decimal  "handling_cost_ex_tax",                     precision: 20, scale: 2
    t.decimal  "handling_cost_inc_tax",                    precision: 20, scale: 2
    t.decimal  "handling_cost_tax",                        precision: 20, scale: 2
    t.decimal  "base_wrapping_cost",                       precision: 20, scale: 2
    t.decimal  "wrapping_cost_ex_tax",                     precision: 20, scale: 2
    t.decimal  "wrapping_cost_inc_tax",                    precision: 20, scale: 2
    t.decimal  "wrapping_cost_tax",                        precision: 20, scale: 2
    t.decimal  "store_credit",                             precision: 20, scale: 2
    t.decimal  "gift_certificate_amount",                  precision: 20, scale: 2
    t.integer  "shipping_cost_tax_class_id", limit: 4
    t.integer  "handling_cost_tax_class_id", limit: 4
    t.integer  "wrapping_cost_tax_class_id", limit: 4
    t.integer  "active",                     limit: 1
    t.text     "ip_address",                 limit: 65535
    t.text     "order_source",               limit: 255
    t.datetime "date_modified"
    t.datetime "date_shipped"
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
  end

  add_index "orders", ["billing_address_id"], name: "index_orders_on_billing_address_id", using: :btree
  add_index "orders", ["coupon_id"], name: "index_orders_on_coupon_id", using: :btree
  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
  add_index "orders", ["staff_id"], name: "index_orders_on_staff_id", using: :btree
  add_index "orders", ["status_id"], name: "index_orders_on_status_id", using: :btree

  create_table "producer_countries", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "short_name", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "producer_regions", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "producer_country_id", limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "producers", force: :cascade do |t|
    t.string   "name",                limit: 255
    t.integer  "producer_country_id", limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "product_categories", force: :cascade do |t|
    t.integer  "product_id",  limit: 4, null: false
    t.integer  "category_id", limit: 4, null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "product_categories", ["category_id"], name: "index_product_categories_on_category_id", using: :btree
  add_index "product_categories", ["product_id"], name: "index_product_categories_on_product_id", using: :btree

  create_table "product_no_vintages", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "product_package_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "product_sizes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "product_sub_types", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.integer  "product_type_id", limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "product_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "short_name", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "products", force: :cascade do |t|
    t.text     "sku",                       limit: 255
    t.text     "name",                      limit: 255
    t.integer  "inventory",                 limit: 4
    t.datetime "date_created"
    t.decimal  "weight",                                  precision: 20, scale: 2
    t.decimal  "height",                                  precision: 20, scale: 2
    t.decimal  "width",                                   precision: 20, scale: 2
    t.decimal  "depth",                                   precision: 20, scale: 2
    t.integer  "visible",                   limit: 1
    t.integer  "featured",                  limit: 1
    t.text     "availability",              limit: 255
    t.datetime "date_modified"
    t.datetime "date_last_imported"
    t.integer  "num_sold",                  limit: 8
    t.integer  "num_viewed",                limit: 8
    t.text     "upc",                       limit: 65535
    t.text     "bin_picking_num",           limit: 65535
    t.text     "search_keywords",           limit: 65535
    t.text     "meta_keywords",             limit: 65535
    t.text     "description",               limit: 65535
    t.text     "meta_description",          limit: 65535
    t.text     "page_title",                limit: 65535
    t.decimal  "retail_price",                            precision: 20, scale: 2
    t.decimal  "sale_price",                              precision: 20, scale: 2
    t.decimal  "calculated_price",                        precision: 20, scale: 2
    t.integer  "inventory_warning_level",   limit: 4
    t.text     "inventory_tracking",        limit: 65535
    t.text     "keyword_filter",            limit: 65535
    t.integer  "sort_order",                limit: 4
    t.integer  "related_products",          limit: 4
    t.integer  "rating_total",              limit: 4
    t.integer  "rating_count",              limit: 4
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.integer  "producer_id",               limit: 4
    t.integer  "product_type_id",           limit: 4
    t.integer  "warehouse_id",              limit: 4
    t.integer  "product_size_id",           limit: 4
    t.string   "name_no_ws",                limit: 255
    t.string   "name_no_winery",            limit: 255
    t.string   "name_no_vintage",           limit: 255
    t.string   "name_no_winery_no_vintage", limit: 255
    t.string   "portfolio_name",            limit: 255
    t.integer  "current",                   limit: 1
    t.integer  "display",                   limit: 1
    t.string   "retail_ws",                 limit: 255
    t.string   "blend_type",                limit: 255
    t.string   "vintage",                   limit: 255
    t.integer  "order_1",                   limit: 4
    t.integer  "order_2",                   limit: 4
    t.decimal  "combined_order",                          precision: 10
    t.string   "portfolio_region",          limit: 255
    t.integer  "case_size",                 limit: 2
    t.string   "price_id",                  limit: 255
    t.integer  "organic_cert",              limit: 1
    t.integer  "organic_pract",             limit: 1
    t.integer  "organic_min",               limit: 1
    t.integer  "vegan",                     limit: 1
    t.integer  "vegetarian",                limit: 1
    t.integer  "bio_cert",                  limit: 1
    t.integer  "bio_pract",                 limit: 1
    t.integer  "filtration",                limit: 1
    t.integer  "fining",                    limit: 1
    t.integer  "so2",                       limit: 1
    t.integer  "producer_country_id",       limit: 4
    t.integer  "producer_region_id",        limit: 4
    t.integer  "product_sub_type_id",       limit: 4
    t.integer  "product_package_type_id",   limit: 4
    t.integer  "product_no_vintage_id",     limit: 4
  end

  create_table "revisions", force: :cascade do |t|
    t.datetime "next_update_time"
    t.text     "notes",            limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "staff_time_periods", force: :cascade do |t|
    t.integer  "staff_id",         limit: 4
    t.string   "name",             limit: 255
    t.integer  "start_day",        limit: 4
    t.integer  "end_day",          limit: 4
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "time_period_type", limit: 1
    t.integer  "display",          limit: 1
    t.integer  "order",            limit: 4
    t.string   "update_function",  limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "staffs", force: :cascade do |t|
    t.string   "firstname",       limit: 255
    t.string   "lastname",        limit: 255
    t.string   "nickname",        limit: 255
    t.string   "email",           limit: 255
    t.string   "logon_details",   limit: 255
    t.string   "contact_number",  limit: 255
    t.string   "state",           limit: 255
    t.string   "country",         limit: 255
    t.string   "user_type",       limit: 255
    t.integer  "display_report",  limit: 1
    t.integer  "invoice_rights",  limit: 1
    t.integer  "product_rights",  limit: 1
    t.integer  "payment_rights",  limit: 1
    t.integer  "active",          limit: 1
    t.string   "password_digest", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "staffs", ["active"], name: "index_staffs_on_active", using: :btree
  add_index "staffs", ["display_report"], name: "index_staffs_on_display_report", using: :btree
  add_index "staffs", ["invoice_rights"], name: "index_staffs_on_invoice_rights", using: :btree
  add_index "staffs", ["nickname"], name: "index_staffs_on_nickname", using: :btree
  add_index "staffs", ["payment_rights"], name: "index_staffs_on_payment_rights", using: :btree
  add_index "staffs", ["product_rights"], name: "index_staffs_on_product_rights", using: :btree

  create_table "statuses", force: :cascade do |t|
    t.text     "name",        limit: 255
    t.text     "alt_name",    limit: 255
    t.integer  "order",       limit: 4
    t.integer  "in_use",      limit: 1
    t.integer  "confirmed",   limit: 1
    t.integer  "in_transit",  limit: 1
    t.integer  "delivered",   limit: 1
    t.integer  "picking",     limit: 1
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "valid_order", limit: 1
  end

  create_table "warehouses", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

end
