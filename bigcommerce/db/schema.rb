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

ActiveRecord::Schema.define(version: 20180921001018) do

  create_table "account_emails", force: :cascade do |t|
    t.string   "receive_address",   limit: 255
    t.string   "send_address",      limit: 255
    t.text     "content",           limit: 65535
    t.string   "email_type",        limit: 255
    t.string   "selected_invoices", limit: 255
    t.integer  "customer_id",       limit: 4
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "cc",                limit: 255
    t.string   "bcc",               limit: 255
    t.text     "content_second",    limit: 65535
  end

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
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.decimal  "lat",                       precision: 12, scale: 7
    t.decimal  "lng",                       precision: 12, scale: 7
  end

  add_index "addresses", ["customer_id"], name: "index_addresses_on_customer_id", using: :btree

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "average_periods", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "days",       limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "bigcommerce_order_products", force: :cascade do |t|
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

  add_index "bigcommerce_order_products", ["order_id"], name: "index_bigcommerce_order_products_on_order_id", using: :btree
  add_index "bigcommerce_order_products", ["order_shipping_id"], name: "index_bigcommerce_order_products_on_order_shipping_id", using: :btree
  add_index "bigcommerce_order_products", ["product_id"], name: "index_bigcommerce_order_products_on_product_id", using: :btree

  create_table "bigcommerce_orders", force: :cascade do |t|
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
    t.string   "xero_invoice_id",            limit: 36
    t.string   "xero_invoice_number",        limit: 36
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
  end

  add_index "bigcommerce_orders", ["billing_address_id"], name: "index_bigcommerce_orders_on_billing_address_id", using: :btree
  add_index "bigcommerce_orders", ["coupon_id"], name: "index_bigcommerce_orders_on_coupon_id", using: :btree
  add_index "bigcommerce_orders", ["customer_id"], name: "index_bigcommerce_orders_on_customer_id", using: :btree
  add_index "bigcommerce_orders", ["staff_id"], name: "index_bigcommerce_orders_on_staff_id", using: :btree
  add_index "bigcommerce_orders", ["status_id"], name: "index_bigcommerce_orders_on_status_id", using: :btree
  add_index "bigcommerce_orders", ["xero_invoice_id"], name: "index_bigcommerce_orders_on_xero_invoice_id", using: :btree
  add_index "bigcommerce_orders", ["xero_invoice_number"], name: "index_bigcommerce_orders_on_xero_invoice_number", using: :btree

  create_table "bootsy_image_galleries", force: :cascade do |t|
    t.integer  "bootsy_resource_id",   limit: 4
    t.string   "bootsy_resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bootsy_images", force: :cascade do |t|
    t.string   "image_file",       limit: 255
    t.integer  "image_gallery_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "contact_roles", force: :cascade do |t|
    t.string   "role",              limit: 255
    t.string   "staff_role",        limit: 255
    t.integer  "contact_role_sort", limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",                     limit: 255
    t.string   "number",                   limit: 255
    t.string   "area_code",                limit: 255
    t.string   "phone_type",               limit: 255
    t.string   "xero_contact_id",          limit: 36
    t.integer  "customer_id",              limit: 4
    t.string   "salesforce_contact_id",    limit: 255
    t.string   "personal_number",          limit: 255
    t.text     "preferred_contact_number", limit: 65535
    t.text     "time_unavailable",         limit: 65535
  end

  create_table "coupons", force: :cascade do |t|
    t.text     "name",       limit: 255, null: false
    t.text     "code",       limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "courier_statuses", force: :cascade do |t|
    t.text     "name",          limit: 255
    t.text     "alt_name",      limit: 255
    t.integer  "order",         limit: 4
    t.integer  "in_use",        limit: 1
    t.integer  "confirmed",     limit: 1
    t.integer  "send_reminder", limit: 1
    t.integer  "can_update",    limit: 1
    t.text     "description",   limit: 65535
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "cust_contacts", force: :cascade do |t|
    t.integer  "customer_id",       limit: 4
    t.integer  "contact_id",        limit: 4
    t.string   "position",          limit: 255
    t.string   "title",             limit: 255
    t.string   "phone",             limit: 255
    t.string   "fax",               limit: 255
    t.string   "email",             limit: 255
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "receive_statement", limit: 4
    t.integer  "key_sales",         limit: 4
    t.integer  "receive_invoice",   limit: 4
    t.integer  "receive_portfolio", limit: 4
    t.integer  "key_accountant",    limit: 4
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

  create_table "customer_account_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "status",     limit: 255
    t.integer  "alert",      limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "customer_credit_app_references", force: :cascade do |t|
    t.integer  "customer_credit_app_id", limit: 4
    t.integer  "customer_id",            limit: 4
    t.text     "company_name",           limit: 65535
    t.text     "contact_name",           limit: 65535
    t.text     "check1",                 limit: 65535
    t.text     "check2",                 limit: 65535
    t.text     "check3",                 limit: 65535
    t.text     "check4",                 limit: 65535
    t.text     "notes",                  limit: 65535
    t.integer  "checked_by",             limit: 4
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "customer_credit_app_signeds", force: :cascade do |t|
    t.integer  "customer_credit_app_id", limit: 4
    t.integer  "contact_id",             limit: 4
    t.integer  "customer_id",            limit: 4
    t.integer  "assigned_staff",         limit: 4
    t.integer  "active",                 limit: 4
    t.datetime "end_date"
    t.text     "end_note",               limit: 65535
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "customer_credit_apps", force: :cascade do |t|
    t.integer  "customer_id",                     limit: 4
    t.integer  "credit_application_version",      limit: 4
    t.datetime "date_signed"
    t.integer  "director_signed",                 limit: 4
    t.text     "company_name",                    limit: 255
    t.text     "trading_name",                    limit: 255
    t.text     "abn",                             limit: 255
    t.integer  "abn_checked",                     limit: 4
    t.integer  "abn_checked_staff_id",            limit: 4
    t.text     "liquor_license_number",           limit: 255
    t.integer  "liquor_license_checked",          limit: 4
    t.integer  "liquor_license_checked_staff_id", limit: 4
    t.text     "address",                         limit: 65535
    t.text     "street",                          limit: 65535
    t.text     "street_2",                        limit: 65535
    t.text     "city",                            limit: 65535
    t.text     "state",                           limit: 65535
    t.text     "postcode",                        limit: 65535
    t.text     "phone",                           limit: 65535
    t.text     "fax",                             limit: 65535
    t.datetime "business_commenced"
    t.string   "current_premises",                limit: 255
    t.datetime "date_occupied"
    t.string   "payment_method_credit_app",       limit: 255
    t.string   "payment_method",                  limit: 255
    t.datetime "payment_method_updated_date"
    t.string   "credit_terms",                    limit: 255
    t.integer  "credit_days",                     limit: 4
    t.integer  "tolerance_days",                  limit: 4
    t.string   "credit_app_doc_id",               limit: 255
    t.integer  "credit_limit",                    limit: 4
    t.integer  "reference_check",                 limit: 4
    t.datetime "approved_date"
    t.integer  "approved_by",                     limit: 4
    t.integer  "staff_id",                        limit: 4
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.text     "note",                            limit: 65535
  end

  add_index "customer_credit_apps", ["credit_application_version"], name: "index_customer_credit_apps_on_credit_application_version", using: :btree
  add_index "customer_credit_apps", ["customer_id"], name: "index_customer_credit_apps_on_customer_id", using: :btree

  create_table "customer_leads", force: :cascade do |t|
    t.text     "firstname",              limit: 255
    t.text     "lastname",               limit: 255
    t.text     "company",                limit: 255
    t.text     "email",                  limit: 255
    t.text     "phone",                  limit: 255
    t.text     "actual_name",            limit: 65535
    t.text     "region",                 limit: 65535
    t.integer  "staff_id",               limit: 4
    t.integer  "cust_type_id",           limit: 4
    t.integer  "cust_group_id",          limit: 4
    t.integer  "cust_style_id",          limit: 4
    t.datetime "date_created"
    t.datetime "date_modified"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.float    "latitude",               limit: 24
    t.float    "longitude",              limit: 24
    t.text     "address",                limit: 65535
    t.text     "mobile_phone",           limit: 65535
    t.text     "website",                limit: 65535
    t.text     "img",                    limit: 65535
    t.string   "salesforce_lead_id",     limit: 255
    t.string   "street",                 limit: 255
    t.string   "city",                   limit: 255
    t.string   "state",                  limit: 255
    t.string   "postalcode",             limit: 255
    t.string   "country",                limit: 255
    t.string   "perferred_contact_time", limit: 255
    t.text     "useful_information",     limit: 65535
    t.integer  "customer_id",            limit: 4
    t.datetime "turn_customer_date"
    t.text     "featured_image",         limit: 65535
    t.string   "google_place_id",        limit: 255
  end

  add_index "customer_leads", ["cust_group_id"], name: "index_customer_leads_on_cust_group_id", using: :btree
  add_index "customer_leads", ["cust_type_id"], name: "index_customer_leads_on_cust_type_id", using: :btree
  add_index "customer_leads", ["staff_id"], name: "index_customer_leads_on_staff_id", using: :btree

  create_table "customer_regions", force: :cascade do |t|
    t.string   "region",     limit: 36, null: false
    t.integer  "sub_of",     limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "customer_regions", ["region"], name: "region", unique: true, using: :btree

  create_table "customer_states", force: :cascade do |t|
    t.string   "state",      limit: 255
    t.string   "state_full", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "customer_tags", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "role",           limit: 255
    t.integer  "customer_id",    limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "address",        limit: 255
    t.string   "state",          limit: 255
    t.string   "staff_nickname", limit: 255
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
    t.datetime "created_at",                                                                 null: false
    t.datetime "updated_at",                                                                 null: false
    t.integer  "cust_style_id",           limit: 4
    t.string   "region",                  limit: 255
    t.string   "xero_contact_id",         limit: 36
    t.string   "salesforce_id",           limit: 255
    t.string   "salesforce_owner_id",     limit: 255
    t.string   "fax",                     limit: 255
    t.string   "website",                 limit: 255
    t.text     "description",             limit: 65535
    t.string   "note",                    limit: 255
    t.text     "payment_requirement",     limit: 65535
    t.string   "email_for_sales",         limit: 255
    t.string   "email_for_accounts",      limit: 255
    t.string   "street",                  limit: 255
    t.string   "city",                    limit: 255
    t.string   "state",                   limit: 255
    t.string   "postcode",                limit: 255
    t.string   "country",                 limit: 255
    t.text     "address",                 limit: 65535
    t.float    "lat",                     limit: 24
    t.float    "lng",                     limit: 24
    t.text     "featured_image",          limit: 65535
    t.string   "google_place_id",         limit: 255
    t.string   "SpecialInstruction1",     limit: 50
    t.string   "SpecialInstruction2",     limit: 50
    t.string   "SpecialInstruction3",     limit: 50
    t.integer  "tolerance_day",           limit: 4,                             default: 30
    t.string   "street_2",                limit: 255
    t.string   "account_type",            limit: 255
    t.string   "payment_method",          limit: 255
    t.string   "default_courier",         limit: 255
    t.integer  "current",                 limit: 4
    t.integer  "priority",                limit: 4
  end

  add_index "customers", ["cust_group_id"], name: "index_customers_on_cust_group_id", using: :btree
  add_index "customers", ["cust_store_id"], name: "index_customers_on_cust_store_id", using: :btree
  add_index "customers", ["cust_type_id"], name: "index_customers_on_cust_type_id", using: :btree
  add_index "customers", ["staff_id"], name: "index_customers_on_staff_id", using: :btree

  create_table "fastway_consignment_items", primary_key: "ItemID", force: :cascade do |t|
    t.string   "Reference",        limit: 255
    t.integer  "Packaging",        limit: 4
    t.integer  "Weight",           limit: 4
    t.integer  "WeightCubic",      limit: 4
    t.datetime "CreateDate"
    t.datetime "PrintDate"
    t.integer  "ExcessLabelCount", limit: 4
    t.string   "LabelColour",      limit: 255
    t.string   "LabelNumber",      limit: 255
    t.integer  "ConsignmentID",    limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "fastway_consignment_items", ["ItemID"], name: "index_fastway_consignment_items_on_ItemID", using: :btree

  create_table "fastway_consignments", primary_key: "ConsignmentID", force: :cascade do |t|
    t.integer  "AccountNumber",           limit: 4
    t.string   "CompanyName",             limit: 255
    t.string   "Address1",                limit: 255
    t.string   "Address2",                limit: 255
    t.string   "City",                    limit: 255
    t.string   "PostCode",                limit: 255
    t.string   "SpecialInstruction1",     limit: 255
    t.string   "SpecialInstruction2",     limit: 255
    t.string   "SpecialInstruction3",     limit: 255
    t.string   "ContactEmail",            limit: 255
    t.string   "ContactPhone",            limit: 255
    t.string   "ContactMobile",           limit: 255
    t.string   "ContactName",             limit: 255
    t.string   "DestinationFranchise",    limit: 255
    t.string   "ThirdPartyConsignmentID", limit: 255
    t.string   "SenderFirstName",         limit: 255
    t.string   "SenderLastName",          limit: 255
    t.string   "SenderContactNumber",     limit: 255
    t.datetime "CreateDate"
    t.integer  "NotificationEmailSent",   limit: 4
    t.integer  "ManifestID",              limit: 4
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "fastway_consignments", ["ConsignmentID"], name: "index_fastway_consignments_on_ConsignmentID", using: :btree

  create_table "fastway_manifests", primary_key: "ManifestID", force: :cascade do |t|
    t.string   "Description",            limit: 255
    t.integer  "AutoImport",             limit: 4
    t.datetime "AutoImportCompleteDate"
    t.integer  "MultiBusinessID",        limit: 4
    t.datetime "CreateDate"
    t.datetime "CloseDate"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "fastway_manifests", ["ManifestID"], name: "index_fastway_manifests_on_ManifestID", using: :btree

  create_table "fastway_traces", force: :cascade do |t|
    t.string   "LabelNumber",        limit: 255
    t.string   "Type",               limit: 255
    t.string   "Courier",            limit: 255
    t.string   "Description",        limit: 255
    t.datetime "Date"
    t.datetime "UploadDate"
    t.string   "Name",               limit: 255
    t.string   "Status",             limit: 255
    t.string   "Franchise",          limit: 255
    t.string   "StatusDescription",  limit: 255
    t.string   "contactName",        limit: 255
    t.string   "company",            limit: 255
    t.string   "address1",           limit: 255
    t.string   "address2",           limit: 255
    t.string   "address3",           limit: 255
    t.string   "address4",           limit: 255
    t.string   "address5",           limit: 255
    t.string   "address6",           limit: 255
    t.string   "address7",           limit: 255
    t.string   "address8",           limit: 255
    t.string   "comment",            limit: 255
    t.string   "Signature",          limit: 255
    t.string   "DistributedTo",      limit: 255
    t.text     "ParcelConnectAgent", limit: 65535
    t.string   "Reference",          limit: 255
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  create_table "order_actions", force: :cascade do |t|
    t.integer  "order_id",   limit: 4,  null: false
    t.string   "action",     limit: 20, null: false
    t.integer  "task_id",    limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "order_histories", force: :cascade do |t|
    t.integer  "order_id",            limit: 4
    t.integer  "customer_id",         limit: 4,                              null: false
    t.integer  "status_id",           limit: 4
    t.integer  "courier_status_id",   limit: 4
    t.string   "account_status",      limit: 255
    t.string   "street",              limit: 255
    t.string   "city",                limit: 255
    t.string   "state",               limit: 255
    t.string   "postcode",            limit: 255
    t.string   "country",             limit: 255
    t.string   "address",             limit: 255
    t.integer  "staff_id",            limit: 4
    t.decimal  "total_inc_tax",                     precision: 10, scale: 4
    t.integer  "qty",                 limit: 3,                              null: false
    t.integer  "items_shipped",       limit: 3
    t.decimal  "subtotal",                          precision: 10, scale: 4
    t.decimal  "discount_rate",                     precision: 10, scale: 4
    t.decimal  "discount_amount",                   precision: 10, scale: 4
    t.decimal  "handling_cost",                     precision: 10, scale: 4
    t.decimal  "shipping_cost",                     precision: 10, scale: 4
    t.decimal  "wrapping_cost",                     precision: 10, scale: 4
    t.decimal  "wet",                               precision: 10, scale: 4
    t.decimal  "gst",                               precision: 10, scale: 4
    t.text     "staff_notes",         limit: 65535
    t.text     "customer_notes",      limit: 65535
    t.integer  "active",              limit: 1
    t.string   "xero_invoice_id",     limit: 255
    t.string   "xero_invoice_number", limit: 255
    t.string   "source",              limit: 255
    t.string   "source_id",           limit: 255
    t.datetime "date_created"
    t.datetime "date_shipped"
    t.integer  "created_by",          limit: 4
    t.integer  "last_updated_by",     limit: 4
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
  end

  add_index "order_histories", ["customer_id"], name: "index_order_histories_on_customer_id", using: :btree
  add_index "order_histories", ["staff_id"], name: "index_order_histories_on_staff_id", using: :btree
  add_index "order_histories", ["status_id"], name: "index_order_histories_on_status_id", using: :btree

  create_table "order_product_histories", force: :cascade do |t|
    t.integer  "order_id",          limit: 4,                             null: false
    t.integer  "order_history_id",  limit: 4,                             null: false
    t.integer  "product_id",        limit: 4,                             null: false
    t.integer  "order_shipping_id", limit: 4
    t.integer  "qty",               limit: 3,                             null: false
    t.integer  "qty_shipped",       limit: 3,                             null: false
    t.decimal  "price_luc",                       precision: 9, scale: 4, null: false
    t.decimal  "base_price",                      precision: 9, scale: 4, null: false
    t.decimal  "discount",                        precision: 9, scale: 4, null: false
    t.decimal  "order_discount",                  precision: 9, scale: 4, null: false
    t.decimal  "price_handling",                  precision: 9, scale: 4, null: false
    t.decimal  "price_inc_tax",                   precision: 9, scale: 4, null: false
    t.decimal  "price_wet",                       precision: 9, scale: 4, null: false
    t.decimal  "price_gst",                       precision: 9, scale: 4, null: false
    t.decimal  "price_discounted",                precision: 9, scale: 4
    t.integer  "stock_previous",    limit: 4
    t.integer  "stock_current",     limit: 4
    t.integer  "stock_incremental", limit: 4
    t.integer  "display",           limit: 4
    t.integer  "damaged",           limit: 4
    t.text     "note",              limit: 65535
    t.integer  "created_by",        limit: 4
    t.integer  "updated_by",        limit: 4
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.datetime "revision_date"
  end

  add_index "order_product_histories", ["order_history_id"], name: "index_order_product_histories_on_order_history_id", using: :btree
  add_index "order_product_histories", ["order_id"], name: "index_order_product_histories_on_order_id", using: :btree
  add_index "order_product_histories", ["order_shipping_id"], name: "index_order_product_histories_on_order_shipping_id", using: :btree
  add_index "order_product_histories", ["product_id"], name: "index_order_product_histories_on_product_id", using: :btree

  create_table "order_products", force: :cascade do |t|
    t.integer  "order_id",          limit: 4,                             null: false
    t.integer  "product_id",        limit: 4,                             null: false
    t.integer  "order_shipping_id", limit: 4
    t.integer  "qty",               limit: 3,                             null: false
    t.integer  "qty_shipped",       limit: 3
    t.decimal  "price_luc",                       precision: 9, scale: 4, null: false
    t.decimal  "base_price",                      precision: 9, scale: 4, null: false
    t.decimal  "discount",                        precision: 9, scale: 4, null: false
    t.decimal  "order_discount",                  precision: 9, scale: 4, null: false
    t.decimal  "price_handling",                  precision: 9, scale: 4, null: false
    t.decimal  "price_inc_tax",                   precision: 9, scale: 4, null: false
    t.decimal  "price_wet",                       precision: 9, scale: 4, null: false
    t.decimal  "price_gst",                       precision: 9, scale: 4, null: false
    t.integer  "stock_previous",    limit: 4
    t.integer  "stock_current",     limit: 4
    t.integer  "stock_incremental", limit: 4
    t.integer  "display",           limit: 4
    t.integer  "damaged",           limit: 4
    t.text     "note",              limit: 65535
    t.integer  "created_by",        limit: 4
    t.integer  "updated_by",        limit: 4
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.decimal  "price_discounted",                precision: 9, scale: 4
    t.datetime "revision_date"
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

  create_table "order_types", force: :cascade do |t|
    t.string   "name",                    limit: 3
    t.string   "description",             limit: 120
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.decimal  "item_price_factor",                   precision: 5, scale: 2
    t.boolean  "item_wet"
    t.boolean  "item_gst"
    t.decimal  "based_price_deduction",               precision: 8, scale: 2
    t.decimal  "hidden_wet_price_factor",             precision: 5, scale: 2
    t.string   "sale_type",               limit: 9
    t.string   "product_type",            limit: 9
  end

  create_table "orders", force: :cascade do |t|
    t.integer  "customer_id",             limit: 4,                              null: false
    t.integer  "status_id",               limit: 4
    t.integer  "staff_id",                limit: 4
    t.decimal  "total_inc_tax",                         precision: 10, scale: 4
    t.integer  "qty",                     limit: 3,                              null: false
    t.integer  "items_shipped",           limit: 3
    t.decimal  "subtotal",                              precision: 10, scale: 4
    t.decimal  "discount_rate",                         precision: 10, scale: 4
    t.decimal  "discount_amount",                       precision: 10, scale: 4
    t.decimal  "handling_cost",                         precision: 10, scale: 4
    t.decimal  "shipping_cost",                         precision: 10, scale: 4
    t.decimal  "wrapping_cost",                         precision: 10, scale: 4
    t.decimal  "wet",                                   precision: 10, scale: 4
    t.decimal  "gst",                                   precision: 10, scale: 4
    t.text     "staff_notes",             limit: 65535
    t.text     "customer_notes",          limit: 65535
    t.integer  "active",                  limit: 1
    t.string   "xero_invoice_id",         limit: 255
    t.string   "xero_invoice_number",     limit: 255
    t.string   "source",                  limit: 255
    t.string   "source_id",               limit: 255
    t.datetime "date_created"
    t.datetime "date_shipped"
    t.integer  "created_by",              limit: 4
    t.integer  "last_updated_by",         limit: 4
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
    t.integer  "courier_status_id",       limit: 4
    t.string   "account_status",          limit: 255
    t.text     "street",                  limit: 65535
    t.string   "city",                    limit: 255
    t.string   "state",                   limit: 255
    t.string   "postcode",                limit: 255
    t.string   "country",                 limit: 255
    t.string   "address",                 limit: 255
    t.text     "track_number",            limit: 65535
    t.float    "modified_wet",            limit: 24
    t.string   "billing_address",         limit: 255
    t.text     "delivery_instruction",    limit: 65535
    t.string   "SpecialInstruction1",     limit: 50
    t.string   "SpecialInstruction2",     limit: 50
    t.string   "SpecialInstruction3",     limit: 50
    t.string   "customer_purchase_order", limit: 255
    t.datetime "eta"
    t.string   "street_2",                limit: 255
    t.string   "ship_name",               limit: 255
    t.string   "proof_of_delivery",       limit: 255
    t.integer  "scot_pac_load",           limit: 4
    t.string   "type",                    limit: 3
  end

  add_index "orders", ["customer_id"], name: "index_orders_on_customer_id", using: :btree
  add_index "orders", ["staff_id"], name: "index_orders_on_staff_id", using: :btree
  add_index "orders", ["status_id"], name: "index_orders_on_status_id", using: :btree

  create_table "portfolios", force: :cascade do |t|
    t.datetime "date_start"
    t.datetime "date_end"
    t.text     "name",       limit: 65535
    t.text     "pipe",       limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

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

  create_table "product_lable_relations", force: :cascade do |t|
    t.integer  "product_id",       limit: 4
    t.integer  "product_lable_id", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "number",           limit: 4
  end

  create_table "product_lables", force: :cascade do |t|
    t.string   "name",       limit: 30, null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "product_no_vintages", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "product_no_ws", force: :cascade do |t|
    t.string   "name",                  limit: 255
    t.integer  "product_no_vintage_id", limit: 4
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "selected",              limit: 4
    t.integer  "warehouse_id",          limit: 4
    t.string   "row",                   limit: 255
    t.string   "column",                limit: 255
    t.string   "area",                  limit: 255
    t.integer  "case_size",             limit: 4
    t.integer  "product_status_id",     limit: 4
  end

  add_index "product_no_ws", ["product_no_vintage_id"], name: "index_product_no_ws_on_product_no_vintage_id", using: :btree

  create_table "product_notes", force: :cascade do |t|
    t.integer  "task_id",      limit: 4
    t.integer  "created_by",   limit: 4
    t.integer  "product_id",   limit: 4
    t.integer  "rating",       limit: 4
    t.text     "note",         limit: 65535
    t.string   "intention",    limit: 255
    t.decimal  "price",                      precision: 7, scale: 3
    t.decimal  "price_luc",                  precision: 7, scale: 3
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "product_name", limit: 255
    t.integer  "version",      limit: 4
    t.integer  "tasted",       limit: 4
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

  create_table "product_statuses", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
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
    t.integer  "product_no_ws_id",          limit: 4
    t.integer  "on_order",                  limit: 1
    t.integer  "sale_term_1",               limit: 4
    t.integer  "sale_term_2",               limit: 4
    t.integer  "sale_term_3",               limit: 4
    t.integer  "sale_term_4",               limit: 4
    t.decimal  "monthly_supply",                          precision: 6, scale: 2
  end

  create_table "projections", force: :cascade do |t|
    t.integer  "customer_id",     limit: 4,   null: false
    t.string   "customer_name",   limit: 120
    t.integer  "q_lines",         limit: 1
    t.integer  "q_bottles",       limit: 2
    t.float    "q_avgluc",        limit: 24
    t.string   "quarter",         limit: 6
    t.boolean  "recent"
    t.integer  "created_by_id",   limit: 4,   null: false
    t.string   "created_by_name", limit: 50
    t.string   "sale_rep_name",   limit: 50
    t.integer  "sale_rep_id",     limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "promotions", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.datetime "date_start"
    t.datetime "date_end"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "rate",        limit: 4
    t.text     "description", limit: 65535
  end

  create_table "revisions", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "attempt_count", limit: 4
    t.string   "description",   limit: 255
  end

  create_table "sale_rate_terms", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "days_from",  limit: 4
    t.integer  "days_until", limit: 4
    t.integer  "weight",     limit: 4
    t.integer  "term",       limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "staff_calendar_addresses", force: :cascade do |t|
    t.integer  "staff_id",         limit: 4
    t.text     "calendar_address", limit: 65535
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "sync_calendar",    limit: 4
  end

  add_index "staff_calendar_addresses", ["staff_id"], name: "index_staff_calendar_addresses_on_staff_id", using: :btree

  create_table "staff_daily_samples", id: false, force: :cascade do |t|
    t.integer  "staff_id",   limit: 4
    t.integer  "product_id", limit: 4
    t.date     "date"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "staff_group_items", force: :cascade do |t|
    t.integer  "staff_group_id", limit: 4
    t.integer  "item_id",        limit: 4
    t.string   "item_model",     limit: 255
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "staff_group_items", ["staff_group_id", "item_id", "item_model"], name: "index_staff_group_items", unique: true, using: :btree

  create_table "staff_groups", force: :cascade do |t|
    t.integer  "staff_id",   limit: 4
    t.string   "group_name", limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
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
    t.string   "firstname",        limit: 255
    t.string   "lastname",         limit: 255
    t.string   "nickname",         limit: 255
    t.string   "email",            limit: 255
    t.string   "logon_details",    limit: 255
    t.string   "contact_number",   limit: 255
    t.string   "state",            limit: 255
    t.string   "country",          limit: 255
    t.string   "user_type",        limit: 255
    t.integer  "display_report",   limit: 1
    t.integer  "invoice_rights",   limit: 1
    t.integer  "product_rights",   limit: 1
    t.integer  "payment_rights",   limit: 1
    t.integer  "active",           limit: 1
    t.string   "password_digest",  limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "can_update",       limit: 1
    t.integer  "pending_orders",   limit: 1
    t.string   "salesforce_email", limit: 255
    t.integer  "staff_order",      limit: 4
    t.string   "access_token",     limit: 255
    t.string   "refresh_token",    limit: 255
    t.integer  "pick_up_id",       limit: 4
    t.integer  "sales_list_right", limit: 4
    t.integer  "calendar_right",   limit: 4
    t.integer  "report_to",        limit: 4
  end

  add_index "staffs", ["active"], name: "index_staffs_on_active", using: :btree
  add_index "staffs", ["display_report"], name: "index_staffs_on_display_report", using: :btree
  add_index "staffs", ["invoice_rights"], name: "index_staffs_on_invoice_rights", using: :btree
  add_index "staffs", ["nickname"], name: "index_staffs_on_nickname", using: :btree
  add_index "staffs", ["payment_rights"], name: "index_staffs_on_payment_rights", using: :btree
  add_index "staffs", ["product_rights"], name: "index_staffs_on_product_rights", using: :btree

  create_table "statuses", force: :cascade do |t|
    t.text     "name",             limit: 255
    t.text     "alt_name",         limit: 255
    t.integer  "order",            limit: 4
    t.integer  "in_use",           limit: 1
    t.integer  "confirmed",        limit: 1
    t.integer  "in_transit",       limit: 1
    t.integer  "delivered",        limit: 1
    t.integer  "picking",          limit: 1
    t.integer  "valid_order",      limit: 1
    t.integer  "xero_import",      limit: 1
    t.integer  "send_reminder",    limit: 1
    t.integer  "can_update",       limit: 1
    t.text     "description",      limit: 65535
    t.integer  "bigcommerce_id",   limit: 4
    t.string   "bigcommerce_name", limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "task_activities", force: :cascade do |t|
    t.integer  "task_id",    limit: 4
    t.text     "log",        limit: 65535
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "task_methods", force: :cascade do |t|
    t.string   "method",     limit: 255, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "task_methods", ["method"], name: "index_task_methods_on_method", using: :btree

  create_table "task_priorities", force: :cascade do |t|
    t.string   "priority_level", limit: 20, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "task_relations", force: :cascade do |t|
    t.integer  "task_id",          limit: 4
    t.integer  "contact_id",       limit: 4
    t.integer  "customer_id",      limit: 4
    t.integer  "cust_group_id",    limit: 4
    t.integer  "staff_id",         limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.datetime "completed_date"
    t.integer  "completed_staff",  limit: 4
    t.integer  "customer_lead_id", limit: 4
  end

  create_table "task_subjects", force: :cascade do |t|
    t.string   "subject",    limit: 255
    t.string   "function",   limit: 255
    t.string   "user_type",  limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "start_date",                        null: false
    t.datetime "end_date"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "title",               limit: 255
    t.text     "description",         limit: 65535
    t.integer  "is_task",             limit: 4
    t.integer  "response_staff",      limit: 4
    t.integer  "last_modified_staff", limit: 4
    t.string   "method",              limit: 255
    t.integer  "parent_task",         limit: 4
    t.datetime "completed_date"
    t.integer  "completed_staff",     limit: 4
    t.string   "subject_1",           limit: 255
    t.string   "subject_2",           limit: 255
    t.string   "subject_3",           limit: 255
    t.string   "function",            limit: 255
    t.integer  "expired",             limit: 1
    t.integer  "priority",            limit: 1
    t.string   "accepted",            limit: 10
    t.string   "google_event_id",     limit: 255
    t.integer  "gcal_status",         limit: 4
    t.text     "location",            limit: 65535
    t.text     "summary",             limit: 65535
    t.integer  "portfolio_id",        limit: 4
    t.integer  "promotion_id",        limit: 4
    t.string   "pro_note_include",    limit: 255
    t.string   "salesforce_task_id",  limit: 255
  end

  create_table "tax_percentages", force: :cascade do |t|
    t.string   "tax_name",       limit: 255
    t.decimal  "tax_percentage",             precision: 8, scale: 2
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
  end

  create_table "warehouse_examinings", force: :cascade do |t|
    t.string   "product_name",        limit: 255
    t.string   "country",             limit: 255
    t.integer  "product_no_ws_id",    limit: 4
    t.integer  "current_dm",          limit: 4
    t.integer  "current_vc",          limit: 4
    t.integer  "current_retail",      limit: 4
    t.integer  "current_ws",          limit: 4
    t.integer  "current_total",       limit: 4
    t.integer  "allocation",          limit: 4
    t.integer  "on_order",            limit: 4
    t.integer  "current_stock",       limit: 4
    t.integer  "count_dm",            limit: 4
    t.integer  "count_vc",            limit: 4
    t.integer  "count_retail",        limit: 4
    t.integer  "count_ws",            limit: 4
    t.integer  "count_total",         limit: 4
    t.integer  "count_size",          limit: 4
    t.integer  "count_pack",          limit: 4
    t.integer  "count_loose",         limit: 4
    t.integer  "count_sample",        limit: 4
    t.integer  "difference",          limit: 4
    t.integer  "count_staff_id",      limit: 4
    t.integer  "authorised_staff_id", limit: 4
    t.datetime "count_date"
    t.datetime "authorised_date"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "warehouses", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "xero_account_codes", force: :cascade do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "account_code", limit: 255
    t.string   "account_name", limit: 255
    t.string   "tax_type",     limit: 255
  end

  create_table "xero_calculations", force: :cascade do |t|
    t.string   "invoice_number",                     limit: 255
    t.string   "item_code",                          limit: 255
    t.string   "description",                        limit: 255
    t.integer  "qty",                                limit: 4
    t.decimal  "unit_price_inc_tax",                             precision: 10, scale: 4
    t.decimal  "discount_rate",                                  precision: 10, scale: 4
    t.decimal  "discounted_unit_price",                          precision: 10, scale: 4
    t.decimal  "discounted_ex_gst_unit_price",                   precision: 10, scale: 4
    t.decimal  "discounted_ex_taxes_unit_price",                 precision: 10, scale: 4
    t.decimal  "line_amount_ex_taxes",                           precision: 10, scale: 4
    t.decimal  "line_amount_ex_taxes_rounded",                   precision: 8,  scale: 2
    t.decimal  "wet_unadjusted_order_product_price",             precision: 10, scale: 4
    t.decimal  "wet_unadjusted_total",                           precision: 10, scale: 4
    t.decimal  "ship_deduction",                                 precision: 10, scale: 4
    t.decimal  "subtotal_ex_gst",                                precision: 10, scale: 4
    t.decimal  "wet_adjusted",                                   precision: 10, scale: 4
    t.decimal  "adjustment",                                     precision: 10, scale: 4
    t.decimal  "shipping_ex_gst",                                precision: 8,  scale: 2
    t.decimal  "total_ex_gst",                                   precision: 8,  scale: 2
    t.decimal  "order_total",                                    precision: 8,  scale: 2
    t.decimal  "rounding_error",                                 precision: 8,  scale: 2
    t.string   "account_code",                       limit: 255
    t.string   "tax_type",                           limit: 255
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.decimal  "rounding_error_inc_gst",                         precision: 8,  scale: 2
    t.decimal  "gst",                                            precision: 8,  scale: 2
  end

  create_table "xero_cn_allocations", primary_key: "xero_cn_allocation_id", force: :cascade do |t|
    t.string   "xero_credit_note_id", limit: 36
    t.decimal  "applied_amount",                  precision: 8, scale: 2
    t.datetime "date"
    t.string   "xero_invoice_id",     limit: 36,                          null: false
    t.string   "invoice_number",      limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
    t.string   "status",              limit: 255
    t.string   "credit_note_number",  limit: 255
    t.string   "reference",           limit: 255
  end

  add_index "xero_cn_allocations", ["invoice_number"], name: "index_xero_cn_allocations_on_invoice_number", using: :btree
  add_index "xero_cn_allocations", ["xero_cn_allocation_id"], name: "index_xero_cn_allocations_on_xero_cn_allocation_id", using: :btree
  add_index "xero_cn_allocations", ["xero_credit_note_id"], name: "index_xero_cn_allocations_on_xero_credit_note_id", using: :btree
  add_index "xero_cn_allocations", ["xero_invoice_id"], name: "index_xero_cn_allocations_on_xero_invoice_id", using: :btree

  create_table "xero_cn_line_items", primary_key: "xero_cn_line_item_id", force: :cascade do |t|
    t.string   "xero_credit_note_id", limit: 36,                          null: false
    t.string   "item_code",           limit: 255
    t.string   "description",         limit: 255
    t.decimal  "quantity",                        precision: 8, scale: 2
    t.decimal  "unit_amount",                     precision: 8, scale: 2
    t.decimal  "line_amount",                     precision: 8, scale: 2
    t.decimal  "discount_rate",                   precision: 8, scale: 2
    t.decimal  "tax_amount",                      precision: 8, scale: 2
    t.string   "tax_type",            limit: 255
    t.string   "account_code",        limit: 255
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  add_index "xero_cn_line_items", ["xero_cn_line_item_id"], name: "index_xero_cn_line_items_on_xero_cn_line_item_id", using: :btree
  add_index "xero_cn_line_items", ["xero_credit_note_id"], name: "index_xero_cn_line_items_on_xero_credit_note_id", using: :btree

  create_table "xero_contact_people", force: :cascade do |t|
    t.string   "xero_contact_id",   limit: 36,  null: false
    t.string   "customer_id",       limit: 8,   null: false
    t.string   "first_name",        limit: 255
    t.string   "last_name",         limit: 255
    t.string   "email_address",     limit: 255
    t.boolean  "include_in_emails"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "xero_contact_people", ["customer_id"], name: "index_xero_contact_people_on_customer_id", using: :btree
  add_index "xero_contact_people", ["xero_contact_id"], name: "index_xero_contact_people_on_xero_contact_id", using: :btree

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
    t.string   "note",               limit: 255
  end

  add_index "xero_credit_notes", ["contact_name"], name: "index_xero_credit_notes_on_xero_contact_name", using: :btree
  add_index "xero_credit_notes", ["credit_note_number"], name: "index_xero_credit_notes_on_credit_note_number", using: :btree
  add_index "xero_credit_notes", ["line_amount_type"], name: "index_xero_credit_notes_on_line_amount_type", using: :btree
  add_index "xero_credit_notes", ["status"], name: "index_xero_credit_notes_on_status", using: :btree
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
    t.string   "xero_contact_id",   limit: 36,                           null: false
    t.string   "contact_name",      limit: 255
    t.decimal  "sub_total",                     precision: 10, scale: 2
    t.decimal  "total_tax",                     precision: 10, scale: 2
    t.decimal  "total",                         precision: 10, scale: 2
    t.decimal  "remaining_credit",              precision: 10, scale: 2
    t.datetime "date"
    t.datetime "updated_date"
    t.string   "status",            limit: 255
    t.string   "line_amount_types", limit: 255
    t.string   "currency_code",     limit: 255
    t.boolean  "has_attachments"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.string   "note",              limit: 255
  end

  add_index "xero_overpayments", ["xero_contact_id"], name: "index_xero_overpayments_on_xero_contact_id", using: :btree
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

  create_table "zomato_cuisines", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "active",         limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "priority_group", limit: 4
  end

  create_table "zomato_entities", force: :cascade do |t|
    t.string   "entity_type",  limit: 255
    t.integer  "entity_id",    limit: 4
    t.string   "title",        limit: 255
    t.float    "latitude",     limit: 24
    t.float    "longitude",    limit: 24
    t.integer  "city_id",      limit: 4
    t.string   "city_name",    limit: 255
    t.integer  "country_id",   limit: 4
    t.string   "country_name", limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  create_table "zomato_restaurants", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.string   "url",                  limit: 255
    t.string   "address",              limit: 255
    t.string   "locality",             limit: 255
    t.float    "latitude",             limit: 24
    t.float    "longitude",            limit: 24
    t.string   "zipcode",              limit: 255
    t.integer  "country_id",           limit: 4
    t.integer  "average_cost_for_two", limit: 4
    t.string   "cuisines",             limit: 255
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "customer_id",          limit: 4
    t.integer  "customer_lead_id",     limit: 4
    t.integer  "active",               limit: 4
    t.string   "thumb",                limit: 255
    t.string   "featured_image",       limit: 255
    t.float    "aggregate_rating",     limit: 24
    t.string   "rating_text",          limit: 255
  end

end
