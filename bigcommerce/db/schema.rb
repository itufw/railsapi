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

ActiveRecord::Schema.define(version: 20161019000146) do

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

  create_table "average_periods", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "days",       limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

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
    t.decimal  "store_credit",                          precision: 6, scale: 2
    t.text     "registration_ip_address", limit: 255
    t.text     "notes",                   limit: 65535
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.integer  "cust_style_id",           limit: 4
    t.string   "region",                  limit: 255
    t.string   "xero_contact_id",         limit: 36
  end

  add_index "customers", ["cust_group_id"], name: "index_customers_on_cust_group_id", using: :btree
  add_index "customers", ["cust_store_id"], name: "index_customers_on_cust_store_id", using: :btree
  add_index "customers", ["cust_type_id"], name: "index_customers_on_cust_type_id", using: :btree
  add_index "customers", ["staff_id"], name: "index_customers_on_staff_id", using: :btree

  create_table "order_histories", force: :cascade do |t|
    t.integer  "order_id",                   limit: 4,                             null: false
    t.datetime "date_created"
    t.integer  "customer_id",                limit: 4,                             null: false
    t.integer  "status_id",                  limit: 4,                             null: false
    t.integer  "staff_id",                   limit: 4
    t.decimal  "total_inc_tax",                            precision: 6, scale: 2
    t.decimal  "refunded_amount",                          precision: 6, scale: 2
    t.integer  "qty",                        limit: 3,                             null: false
    t.integer  "items_shipped",              limit: 3
    t.text     "staff_notes",                limit: 65535
    t.text     "customer_notes",             limit: 65535
    t.integer  "billing_address_id",         limit: 4
    t.integer  "coupon_id",                  limit: 4
    t.text     "payment_method",             limit: 255
    t.decimal  "discount_amount",                          precision: 6, scale: 2
    t.decimal  "coupon_discount",                          precision: 6, scale: 2
    t.decimal  "subtotal_ex_tax",                          precision: 6, scale: 2
    t.decimal  "subtotal_inc_tax",                         precision: 6, scale: 2
    t.decimal  "subtotal_tax",                             precision: 6, scale: 2
    t.decimal  "total_ex_tax",                             precision: 6, scale: 2
    t.decimal  "total_tax",                                precision: 6, scale: 2
    t.decimal  "base_shipping_cost",                       precision: 6, scale: 2
    t.decimal  "shipping_cost_ex_tax",                     precision: 6, scale: 2
    t.decimal  "shipping_cost_inc_tax",                    precision: 6, scale: 2
    t.decimal  "shipping_cost_tax",                        precision: 6, scale: 2
    t.decimal  "base_handling_cost",                       precision: 6, scale: 2
    t.decimal  "handling_cost_ex_tax",                     precision: 6, scale: 2
    t.decimal  "handling_cost_inc_tax",                    precision: 6, scale: 2
    t.decimal  "handling_cost_tax",                        precision: 6, scale: 2
    t.decimal  "base_wrapping_cost",                       precision: 6, scale: 2
    t.decimal  "wrapping_cost_ex_tax",                     precision: 6, scale: 2
    t.decimal  "wrapping_cost_inc_tax",                    precision: 6, scale: 2
    t.decimal  "wrapping_cost_tax",                        precision: 6, scale: 2
    t.decimal  "store_credit",                             precision: 6, scale: 2
    t.decimal  "gift_certificate_amount",                  precision: 6, scale: 2
    t.integer  "shipping_cost_tax_class_id", limit: 4
    t.integer  "handling_cost_tax_class_id", limit: 4
    t.integer  "wrapping_cost_tax_class_id", limit: 4
    t.integer  "active",                     limit: 1
    t.text     "ip_address",                 limit: 65535
    t.text     "order_source",               limit: 255
    t.datetime "date_modified"
    t.datetime "date_shipped"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
  end

  add_index "order_histories", ["billing_address_id"], name: "index_order_histories_on_billing_address_id", using: :btree
  add_index "order_histories", ["coupon_id"], name: "index_order_histories_on_coupon_id", using: :btree
  add_index "order_histories", ["customer_id"], name: "index_order_histories_on_customer_id", using: :btree
  add_index "order_histories", ["order_id"], name: "index_order_histories_on_order_id", using: :btree
  add_index "order_histories", ["staff_id"], name: "index_order_histories_on_staff_id", using: :btree
  add_index "order_histories", ["status_id"], name: "index_order_histories_on_status_id", using: :btree

  create_table "order_product_histories", force: :cascade do |t|
    t.integer  "order_history_id",  limit: 4,                         null: false
    t.integer  "order_id",          limit: 4,                         null: false
    t.integer  "product_id",        limit: 4,                         null: false
    t.integer  "order_shipping_id", limit: 4,                         null: false
    t.integer  "qty",               limit: 3,                         null: false
    t.integer  "qty_shipped",       limit: 3,                         null: false
    t.decimal  "base_price",                  precision: 6, scale: 2, null: false
    t.decimal  "price_ex_tax",                precision: 6, scale: 2, null: false
    t.decimal  "price_inc_tax",               precision: 6, scale: 2, null: false
    t.decimal  "price_tax",                   precision: 6, scale: 2, null: false
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
  end

  add_index "order_product_histories", ["order_history_id"], name: "index_order_product_histories_on_order_history_id", using: :btree
  add_index "order_product_histories", ["order_id"], name: "index_order_product_histories_on_order_id", using: :btree
  add_index "order_product_histories", ["order_shipping_id"], name: "index_order_product_histories_on_order_shipping_id", using: :btree
  add_index "order_product_histories", ["product_id"], name: "index_order_product_histories_on_product_id", using: :btree

  create_table "order_products", force: :cascade do |t|
    t.integer  "order_id",          limit: 4,                         null: false
    t.integer  "product_id",        limit: 4,                         null: false
    t.integer  "order_shipping_id", limit: 4,                         null: false
    t.integer  "qty",               limit: 3,                         null: false
    t.integer  "qty_shipped",       limit: 3,                         null: false
    t.decimal  "base_price",                  precision: 6, scale: 2, null: false
    t.decimal  "price_ex_tax",                precision: 6, scale: 2, null: false
    t.decimal  "price_inc_tax",               precision: 6, scale: 2, null: false
    t.decimal  "price_tax",                   precision: 6, scale: 2, null: false
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
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
    t.integer  "customer_id",                limit: 4,                             null: false
    t.integer  "status_id",                  limit: 4
    t.integer  "staff_id",                   limit: 4
    t.decimal  "total_inc_tax",                            precision: 6, scale: 2
    t.decimal  "refunded_amount",                          precision: 6, scale: 2
    t.integer  "qty",                        limit: 3,                             null: false
    t.integer  "items_shipped",              limit: 3
    t.text     "staff_notes",                limit: 65535
    t.text     "customer_notes",             limit: 65535
    t.integer  "billing_address_id",         limit: 4
    t.integer  "coupon_id",                  limit: 4
    t.text     "payment_method",             limit: 255
    t.decimal  "discount_amount",                          precision: 6, scale: 2
    t.decimal  "coupon_discount",                          precision: 6, scale: 2
    t.decimal  "subtotal_ex_tax",                          precision: 6, scale: 2
    t.decimal  "subtotal_inc_tax",                         precision: 6, scale: 2
    t.decimal  "subtotal_tax",                             precision: 6, scale: 2
    t.decimal  "total_ex_tax",                             precision: 6, scale: 2
    t.decimal  "total_tax",                                precision: 6, scale: 2
    t.decimal  "base_shipping_cost",                       precision: 6, scale: 2
    t.decimal  "shipping_cost_ex_tax",                     precision: 6, scale: 2
    t.decimal  "shipping_cost_inc_tax",                    precision: 6, scale: 2
    t.decimal  "shipping_cost_tax",                        precision: 6, scale: 2
    t.decimal  "base_handling_cost",                       precision: 6, scale: 2
    t.decimal  "handling_cost_ex_tax",                     precision: 6, scale: 2
    t.decimal  "handling_cost_inc_tax",                    precision: 6, scale: 2
    t.decimal  "handling_cost_tax",                        precision: 6, scale: 2
    t.decimal  "base_wrapping_cost",                       precision: 6, scale: 2
    t.decimal  "wrapping_cost_ex_tax",                     precision: 6, scale: 2
    t.decimal  "wrapping_cost_inc_tax",                    precision: 6, scale: 2
    t.decimal  "wrapping_cost_tax",                        precision: 6, scale: 2
    t.decimal  "store_credit",                             precision: 6, scale: 2
    t.decimal  "gift_certificate_amount",                  precision: 6, scale: 2
    t.integer  "shipping_cost_tax_class_id", limit: 4
    t.integer  "handling_cost_tax_class_id", limit: 4
    t.integer  "wrapping_cost_tax_class_id", limit: 4
    t.integer  "active",                     limit: 1
    t.text     "ip_address",                 limit: 65535
    t.text     "order_source",               limit: 255
    t.datetime "date_modified"
    t.datetime "date_shipped"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.string   "xero_invoice_id",            limit: 36
    t.string   "xero_invoice_number",        limit: 255
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
    t.decimal  "weight",                                  precision: 6, scale: 2
    t.decimal  "height",                                  precision: 6, scale: 2
    t.decimal  "width",                                   precision: 6, scale: 2
    t.decimal  "depth",                                   precision: 6, scale: 2
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
    t.decimal  "retail_price",                            precision: 6, scale: 2
    t.decimal  "sale_price",                              precision: 6, scale: 2
    t.decimal  "calculated_price",                        precision: 6, scale: 2
    t.integer  "inventory_warning_level",   limit: 4
    t.text     "inventory_tracking",        limit: 65535
    t.text     "keyword_filter",            limit: 65535
    t.integer  "sort_order",                limit: 4
    t.integer  "related_products",          limit: 4
    t.integer  "rating_total",              limit: 4
    t.integer  "rating_count",              limit: 4
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
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
    t.decimal  "combined_order",                          precision: 6, scale: 2
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

  create_table "tax_codes", force: :cascade do |t|
    t.string   "customer_type", limit: 255
    t.string   "tax_code",      limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "tax_percentages", force: :cascade do |t|
    t.string   "tax_name",       limit: 255
    t.decimal  "tax_percentage",             precision: 8, scale: 2
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "xero_cn_allocations", primary_key: "xero_cn_allocation_id", force: :cascade do |t|
    t.string   "xero_credit_note_id", limit: 36
    t.decimal  "applied_amount",                  precision: 8, scale: 2
    t.datetime "date"
    t.string   "xero_invoice_id",     limit: 36,                          null: false
    t.string   "invoice_number",      limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  add_index "xero_cn_allocations", ["invoice_number"], name: "index_xero_cn_allocations_on_invoice_number", using: :btree
  add_index "xero_cn_allocations", ["xero_cn_allocation_id"], name: "index_xero_cn_allocations_on_xero_cn_allocation_id", using: :btree
  add_index "xero_cn_allocations", ["xero_credit_note_id"], name: "index_xero_cn_allocations_on_xero_credit_note_id", using: :btree
  add_index "xero_cn_allocations", ["xero_invoice_id"], name: "index_xero_cn_allocations_on_xero_invoice_id", using: :btree

  create_table "xero_contacts", primary_key: "xero_contact_id", force: :cascade do |t|
    t.string   "name",                            limit: 255
    t.string   "firstname",                       limit: 255
    t.string   "lastname",                        limit: 255
    t.string   "email",                           limit: 255
    t.string   "skype_user_name",                 limit: 255
    t.string   "contact_number",                  limit: 255
    t.string   "contact_status",                  limit: 255
    t.datetime "updated_date"
    t.string   "account_number",                  limit: 255
    t.string   "tax_number",                      limit: 255
    t.string   "bank_account_details",            limit: 255
    t.string   "accounts_receivable_tax_type",    limit: 255
    t.string   "contact_groups",                  limit: 255
    t.string   "default_currency",                limit: 255
    t.string   "purchases_default_account_code",  limit: 255
    t.string   "sales_default_account_code",      limit: 255
    t.boolean  "is_supplier"
    t.boolean  "is_customer"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.decimal  "accounts_receivable_outstanding",             precision: 8, scale: 2
    t.decimal  "accounts_receivable_overdue",                 precision: 8, scale: 2
  end

  add_index "xero_contacts", ["xero_contact_id"], name: "index_xero_contacts_on_xero_contact_id", using: :btree

  create_table "xero_credit_notes", primary_key: "xero_credit_note_id", force: :cascade do |t|
    t.string   "credit_note_number", limit: 255
    t.string   "xero_contact_id",    limit: 36,                          null: false
    t.string   "contact_name",       limit: 255
    t.string   "status",             limit: 255
    t.string   "line_amount_type",   limit: 255
    t.string   "type",               limit: 255
    t.decimal  "sub_total",                      precision: 8, scale: 2
    t.decimal  "total",                          precision: 8, scale: 2
    t.decimal  "total_tax",                      precision: 8, scale: 2
    t.decimal  "remaining_credit",               precision: 8, scale: 2
    t.datetime "date"
    t.datetime "updated_date"
    t.datetime "fully_paid_on_date"
    t.string   "currency_code",      limit: 255
    t.decimal  "currency_rate",                  precision: 8, scale: 2
    t.string   "reference",          limit: 255
    t.boolean  "sent_to_contact"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "xero_credit_notes", ["contact_name"], name: "index_xero_credit_notes_on_xero_contact_name", using: :btree
  add_index "xero_credit_notes", ["credit_note_number"], name: "index_xero_credit_notes_on_credit_note_number", using: :btree
  add_index "xero_credit_notes", ["line_amount_type"], name: "index_xero_credit_notes_on_line_amount_type", using: :btree
  add_index "xero_credit_notes", ["status"], name: "index_xero_credit_notes_on_status", using: :btree
  add_index "xero_credit_notes", ["type"], name: "index_xero_credit_notes_on_type", using: :btree
  add_index "xero_credit_notes", ["xero_contact_id"], name: "index_xero_credit_notes_on_xero_contact_id", using: :btree
  add_index "xero_credit_notes", ["xero_credit_note_id"], name: "index_xero_credit_notes_on_xero_credit_note_id", using: :btree

  create_table "xero_invoice_line_items", primary_key: "xero_invoice_line_item_id", force: :cascade do |t|
    t.string   "xero_invoice_id", limit: 36,                          null: false
    t.string   "item_code",       limit: 255
    t.string   "description",     limit: 255
    t.decimal  "quantity",                    precision: 8, scale: 2
    t.decimal  "unit_amount",                 precision: 8, scale: 2
    t.decimal  "line_amount",                 precision: 8, scale: 2
    t.decimal  "discount_rate",               precision: 8, scale: 2
    t.decimal  "tax_amount",                  precision: 8, scale: 2
    t.string   "tax_type",        limit: 255
    t.string   "account_code",    limit: 255
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.string   "invoice_number",  limit: 255
  end

  add_index "xero_invoice_line_items", ["xero_invoice_id"], name: "index_xero_invoice_line_items_on_xero_invoice_id", using: :btree
  add_index "xero_invoice_line_items", ["xero_invoice_line_item_id"], name: "index_xero_invoice_line_items_on_xero_invoice_line_item_id", using: :btree

  create_table "xero_invoices", primary_key: "xero_invoice_id", force: :cascade do |t|
    t.string   "invoice_number",        limit: 255
    t.string   "xero_contact_id",       limit: 36,                          null: false
    t.string   "contact_name",          limit: 255
    t.decimal  "sub_total",                         precision: 8, scale: 2
    t.decimal  "total_tax",                         precision: 8, scale: 2
    t.decimal  "total",                             precision: 8, scale: 2
    t.decimal  "total_discount",                    precision: 8, scale: 2
    t.decimal  "amount_due",                        precision: 8, scale: 2
    t.decimal  "amount_paid",                       precision: 8, scale: 2
    t.decimal  "amount_credited",                   precision: 8, scale: 2
    t.datetime "date"
    t.datetime "due_date"
    t.datetime "fully_paid_on_date"
    t.datetime "expected_payment_date"
    t.datetime "updated_date"
    t.string   "status",                limit: 255
    t.string   "line_amount_types",     limit: 255
    t.string   "invoice_type",          limit: 255
    t.string   "reference",             limit: 255
    t.string   "currency_code",         limit: 255
    t.decimal  "currency_rate",                     precision: 8, scale: 2
    t.string   "url",                   limit: 255
    t.string   "branding_theme_id",     limit: 36
    t.boolean  "sent_to_contact"
    t.boolean  "has_attachments"
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
  end

  add_index "xero_invoices", ["date"], name: "index_xero_invoices_on_date", using: :btree
  add_index "xero_invoices", ["due_date"], name: "index_xero_invoices_on_due_date", using: :btree
  add_index "xero_invoices", ["expected_payment_date"], name: "index_xero_invoices_on_expected_payment_date", using: :btree
  add_index "xero_invoices", ["fully_paid_on_date"], name: "index_xero_invoices_on_fully_paid_on_date", using: :btree
  add_index "xero_invoices", ["invoice_number"], name: "index_xero_invoices_on_invoice_number", using: :btree
  add_index "xero_invoices", ["invoice_type"], name: "index_xero_invoices_on_invoice_type", using: :btree
  add_index "xero_invoices", ["line_amount_types"], name: "index_xero_invoices_on_line_amount_types", using: :btree
  add_index "xero_invoices", ["reference"], name: "index_xero_invoices_on_reference", using: :btree
  add_index "xero_invoices", ["status"], name: "index_xero_invoices_on_status", using: :btree
  add_index "xero_invoices", ["updated_date"], name: "index_xero_invoices_on_updated_date", using: :btree
  add_index "xero_invoices", ["xero_contact_id"], name: "index_xero_invoices_on_xero_contact_id", using: :btree
  add_index "xero_invoices", ["xero_invoice_id"], name: "index_xero_invoices_on_xero_invoice_id", using: :btree

  create_table "xero_op_allocations", primary_key: "xero_op_allocation_id", force: :cascade do |t|
    t.string   "xero_overpayment_id", limit: 36
    t.decimal  "applied_amount",                  precision: 8, scale: 2
    t.datetime "date"
    t.string   "xero_invoice_id",     limit: 36,                          null: false
    t.string   "invoice_number",      limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  add_index "xero_op_allocations", ["invoice_number"], name: "index_xero_op_allocations_on_invoice_number", using: :btree
  add_index "xero_op_allocations", ["xero_invoice_id"], name: "index_xero_op_allocations_on_xero_invoice_id", using: :btree
  add_index "xero_op_allocations", ["xero_op_allocation_id"], name: "index_xero_op_allocations_on_xero_op_allocation_id", using: :btree
  add_index "xero_op_allocations", ["xero_overpayment_id"], name: "index_xero_op_allocations_on_xero_overpayment_id", using: :btree

  create_table "xero_overpayments", primary_key: "xero_overpayment_id", force: :cascade do |t|
    t.string   "xero_invoice_id",   limit: 36,                 null: false
    t.string   "invoice_number",    limit: 255
    t.string   "xero_contact_id",   limit: 36,                 null: false
    t.string   "contact_name",      limit: 255
    t.decimal  "sub_total",                     precision: 10
    t.decimal  "total_tax",                     precision: 10
    t.decimal  "total",                         precision: 10
    t.decimal  "remaining_credit",              precision: 10
    t.datetime "date"
    t.datetime "updated_date"
    t.string   "type",              limit: 255
    t.string   "status",            limit: 255
    t.string   "line_amount_types", limit: 255
    t.string   "currency_code",     limit: 255
    t.boolean  "has_attachments"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "xero_overpayments", ["invoice_number"], name: "index_xero_overpayments_on_invoice_number", using: :btree
  add_index "xero_overpayments", ["xero_contact_id"], name: "index_xero_overpayments_on_xero_contact_id", using: :btree
  add_index "xero_overpayments", ["xero_invoice_id"], name: "index_xero_overpayments_on_xero_invoice_id", using: :btree
  add_index "xero_overpayments", ["xero_overpayment_id"], name: "index_xero_overpayments_on_xero_overpayment_id", using: :btree

  create_table "xero_payments", primary_key: "xero_payment_id", force: :cascade do |t|
    t.string   "xero_invoice_id", limit: 36
    t.string   "invoice_number",  limit: 255
    t.string   "invoice_type",    limit: 255
    t.string   "xero_contact_id", limit: 36
    t.string   "contact_name",    limit: 255
    t.string   "xero_account_id", limit: 36
    t.decimal  "bank_amount",                 precision: 8, scale: 2
    t.decimal  "amount",                      precision: 8, scale: 2
    t.decimal  "currency_rate",               precision: 8, scale: 2
    t.datetime "date"
    t.datetime "updated_date"
    t.string   "payment_type",    limit: 255
    t.string   "status",          limit: 255
    t.string   "reference",       limit: 255
    t.boolean  "is_reconciled"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
  end

  add_index "xero_payments", ["invoice_number"], name: "index_xero_payments_on_invoice_number", using: :btree
  add_index "xero_payments", ["invoice_type"], name: "index_xero_payments_on_invoice_type", using: :btree
  add_index "xero_payments", ["xero_account_id"], name: "index_xero_payments_on_xero_account_id", using: :btree
  add_index "xero_payments", ["xero_contact_id"], name: "index_xero_payments_on_xero_contact_id", using: :btree
  add_index "xero_payments", ["xero_invoice_id"], name: "index_xero_payments_on_xero_invoice_id", using: :btree
  add_index "xero_payments", ["xero_payment_id"], name: "index_xero_payments_on_xero_payment_id", using: :btree

  create_table "xero_receipts", primary_key: "xero_receipt_id", force: :cascade do |t|
    t.string   "xero_contact_id",   limit: 36
    t.string   "contact_name",      limit: 255
    t.string   "xero_user_id",      limit: 36
    t.string   "user_firstname",    limit: 255
    t.string   "user_lastname",     limit: 255
    t.string   "receipt_number",    limit: 255
    t.string   "status",            limit: 255
    t.decimal  "sub_total",                     precision: 8, scale: 2
    t.decimal  "total_tax",                     precision: 8, scale: 2
    t.decimal  "total",                         precision: 8, scale: 2
    t.datetime "date"
    t.datetime "updated_date"
    t.string   "url",               limit: 255
    t.string   "reference",         limit: 255
    t.string   "line_amount_types", limit: 255
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
  end

  add_index "xero_receipts", ["xero_contact_id"], name: "index_xero_receipts_on_xero_contact_id", using: :btree
  add_index "xero_receipts", ["xero_receipt_id"], name: "index_xero_receipts_on_xero_receipt_id", using: :btree
  add_index "xero_receipts", ["xero_user_id"], name: "index_xero_receipts_on_xero_user_id", using: :btree

end
