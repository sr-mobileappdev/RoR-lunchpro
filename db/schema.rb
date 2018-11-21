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

ActiveRecord::Schema.define(version: 20180820221400) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "api_users", force: :cascade do |t|
    t.string "name"
    t.string "api_key"
    t.boolean "is_enabled", default: false
    t.integer "enabled_by_user_id"
    t.datetime "disabled_at"
    t.integer "disabled_by_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_accessed_at"
  end

  create_table "appointment_slots", force: :cascade do |t|
    t.string "name"
    t.integer "day_of_week"
    t.time "starts_at"
    t.time "ends_at"
    t.integer "staff_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "office_id"
    t.integer "status", default: 1
    t.datetime "deactivated_at"
    t.integer "deactivated_by_id"
    t.datetime "activated_at"
    t.integer "activated_by_id"
    t.integer "slot_type"
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "sales_rep_id"
    t.bigint "office_id"
    t.bigint "appointment_slot_id"
    t.string "rep_notes"
    t.string "office_notes"
    t.bigint "created_by_user_id"
    t.boolean "food_ordered"
    t.boolean "food_sent"
    t.boolean "funds_funded"
    t.string "delivery_notes"
    t.integer "status"
    t.string "bring_food_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "time_zone"
    t.integer "appointment_type", default: 1, null: false
    t.date "appointment_on"
    t.boolean "will_supply_food", default: false
    t.time "starts_at"
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.string "cancel_reason"
    t.time "ends_at"
    t.datetime "rep_confirmed_at"
    t.datetime "office_confirmed_at"
    t.datetime "restaurant_confirmed_at"
    t.integer "restaurant_id"
    t.integer "recommended_cuisines", default: [], array: true
    t.string "title"
    t.datetime "samples_delivered_at"
    t.text "samples_requested", default: [], array: true
    t.boolean "excluded", default: false
    t.integer "origin", default: 3, null: false
    t.integer "recommended_by_id"
    t.integer "updated_by_id"
    t.index ["appointment_slot_id"], name: "index_appointments_on_appointment_slot_id"
    t.index ["appointment_type"], name: "index_appointments_on_appointment_type"
    t.index ["created_by_user_id"], name: "index_appointments_on_created_by_user_id"
    t.index ["office_id"], name: "index_appointments_on_office_id"
    t.index ["sales_rep_id"], name: "index_appointments_on_sales_rep_id"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.string "bank_name"
    t.string "routing_number"
    t.string "account_number"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "postal"
    t.string "phone_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "status", default: 1
    t.integer "account_type"
    t.string "stripe_identifier"
    t.index ["restaurant_id"], name: "index_bank_accounts_on_restaurant_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "status"
    t.string "logo_image"
    t.datetime "deactivated_at"
    t.integer "deactivated_by_id"
  end

  create_table "cuisines", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
  end

  create_table "cuisines_restaurants", id: false, force: :cascade do |t|
    t.bigint "cuisine_id", null: false
    t.bigint "restaurant_id", null: false
    t.index ["cuisine_id", "restaurant_id"], name: "index_cuisines_restaurants_on_cuisine_id_and_restaurant_id"
    t.index ["restaurant_id", "cuisine_id"], name: "index_cuisines_restaurants_on_restaurant_id_and_cuisine_id"
  end

  create_table "delivery_distances", force: :cascade do |t|
    t.integer "radius"
    t.boolean "use_complex"
    t.integer "north"
    t.integer "north_east"
    t.integer "east"
    t.integer "south_east"
    t.integer "south"
    t.integer "south_west"
    t.integer "west"
    t.integer "north_west"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "restaurant_id"
    t.index ["restaurant_id"], name: "index_delivery_distances_on_restaurant_id"
  end

  create_table "diet_restrictions", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
  end

  create_table "diet_restrictions_lunch_packs", force: :cascade do |t|
    t.integer "diet_restriction_id"
    t.integer "lunch_pack_id"
  end

  create_table "diet_restrictions_menu_items", id: false, force: :cascade do |t|
    t.bigint "diet_restriction_id", null: false
    t.bigint "menu_item_id", null: false
    t.index ["diet_restriction_id", "menu_item_id"], name: "diet_restriction_id_and_menu_item_id"
  end

  create_table "diet_restrictions_offices", force: :cascade do |t|
    t.bigint "office_id"
    t.bigint "diet_restriction_id"
    t.integer "staff_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["diet_restriction_id"], name: "index_diet_restrictions_offices_on_diet_restriction_id"
    t.index ["office_id"], name: "index_diet_restrictions_offices_on_office_id"
  end

  create_table "diet_restrictions_providers", id: false, force: :cascade do |t|
    t.bigint "diet_restriction_id", null: false
    t.bigint "provider_id", null: false
    t.index ["diet_restriction_id", "provider_id"], name: "diet_restrictions_providers_diet_id_and_prov_id"
    t.index ["provider_id", "diet_restriction_id"], name: "diet_restrictions_providers_prov_id_and_diet_id"
  end

  create_table "drugs", force: :cascade do |t|
    t.string "brand"
    t.string "generic_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
    t.integer "created_by_id"
  end

  create_table "drugs_sales_reps", force: :cascade do |t|
    t.bigint "sales_rep_id"
    t.bigint "drug_id"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drug_id"], name: "index_drugs_sales_reps_on_drug_id"
    t.index ["sales_rep_id", "drug_id"], name: "index_drugs_sales_reps_on_sales_rep_id_and_drug_id"
  end

  create_table "holiday_exclusions", force: :cascade do |t|
    t.string "name"
    t.date "starts_on"
    t.date "ends_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.integer "status", default: 1
  end

  create_table "holiday_exclusions_offices", id: false, force: :cascade do |t|
    t.bigint "holiday_exclusion_id", null: false
    t.bigint "office_id", null: false
    t.index ["holiday_exclusion_id", "office_id"], name: "holiday_exclusions_offices_excl_id_and_office_id"
    t.index ["office_id", "holiday_exclusion_id"], name: "holiday_exclusions_offices_office_id_and_excl_id"
  end

  create_table "imports", force: :cascade do |t|
    t.string "import_file"
    t.integer "uploaded_by_id"
    t.string "import_model"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "line_items", force: :cascade do |t|
    t.bigint "order_id"
    t.string "name"
    t.integer "quantity"
    t.bigint "cost_cents"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "orderable_id"
    t.string "orderable_type"
    t.integer "parent_line_item_id"
    t.integer "created_by_id"
    t.integer "status", default: 1
    t.integer "people_served"
    t.integer "category"
    t.integer "unit_cost_cents"
    t.index ["order_id"], name: "index_line_items_on_order_id"
  end

  create_table "lunch_packs", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "retail_price_cents"
    t.integer "status"
    t.bigint "ordered_counter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "restaurant_id"
    t.datetime "published_at"
    t.datetime "unpublished_at"
    t.integer "modified_by_user_id"
  end

  create_table "lunch_packs_menu_items", force: :cascade do |t|
    t.bigint "lunch_pack_id"
    t.bigint "menu_item_id"
    t.integer "sort_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lunch_pack_id", "menu_item_id"], name: "index_lunch_packs_menu_items_on_lunch_pack_id_and_menu_item_id"
    t.index ["menu_item_id"], name: "index_lunch_packs_menu_items_on_menu_item_id"
  end

  create_table "menu_item_images", force: :cascade do |t|
    t.string "image"
    t.integer "status", default: 1
    t.integer "position"
    t.string "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "menu_item_id"
  end

  create_table "menu_items", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "people_served"
    t.integer "retail_price_cents"
    t.bigint "modified_by_user_id"
    t.integer "status"
    t.bigint "ordered_counter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "restaurant_id"
    t.integer "category"
    t.datetime "published_at"
    t.datetime "unpublished_at"
    t.boolean "lunchpack", default: false, null: false
    t.integer "wholesale_price_percentage"
    t.index ["modified_by_user_id"], name: "index_menu_items_on_modified_by_user_id"
  end

  create_table "menu_items_menus", id: false, force: :cascade do |t|
    t.bigint "menu_item_id", null: false
    t.bigint "menu_id", null: false
    t.index ["menu_item_id", "menu_id"], name: "index_menu_items_menus_on_menu_item_id_and_menu_id"
  end

  create_table "menu_sub_item_options", force: :cascade do |t|
    t.integer "menu_sub_item_id"
    t.string "option_name"
    t.integer "price_cents", default: 0
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "menu_sub_items", force: :cascade do |t|
    t.integer "menu_item_id"
    t.string "name"
    t.string "description"
    t.integer "qty_allowed", default: 1
    t.integer "base_price_cents", default: 0
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "qty_required", default: 0
  end

  create_table "menus", force: :cascade do |t|
    t.string "name"
    t.time "start_time"
    t.time "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
    t.integer "created_by_user_id"
    t.integer "restaurant_id"
    t.datetime "published_at"
    t.datetime "deactivated_at"
    t.integer "deactivated_by_id"
  end

  create_table "notification_event_recipients", force: :cascade do |t|
    t.string "recipient_type"
    t.integer "status", default: 1
    t.string "title"
    t.integer "priority", default: 2
    t.integer "activated_by_user"
    t.datetime "activated_at"
    t.integer "deactivated_by_user"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notification_event_id"
    t.integer "active_email_template_id"
    t.integer "active_sms_template_id"
    t.integer "active_push_template_id"
    t.boolean "is_email_default", default: false
    t.boolean "is_sms_default", default: false
    t.boolean "is_web_default", default: false
    t.string "content"
    t.string "sms_content"
    t.string "email_content"
  end

  create_table "notification_events", force: :cascade do |t|
    t.string "category_cid"
    t.integer "status", default: 1
    t.string "internal_summary"
    t.integer "activated_by_user"
    t.datetime "activated_at"
    t.integer "deactivated_by_user"
    t.datetime "deactivated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_templates", force: :cascade do |t|
    t.string "template_type"
    t.integer "status"
    t.string "service"
    t.string "key"
    t.integer "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "template_content"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.integer "status", default: 1
    t.string "title"
    t.integer "notification_event_id"
    t.string "relatable_type"
    t.integer "relatable_id"
    t.integer "priority"
    t.datetime "read_at"
    t.datetime "removed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "notified_at"
    t.jsonb "related_objects"
    t.datetime "queued_at"
    t.integer "delay_minutes", default: 0
    t.jsonb "status_summary"
    t.string "web_summary"
  end

  create_table "office_device_logs", force: :cascade do |t|
    t.integer "office_id"
    t.datetime "timestamp"
    t.string "app_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "office_name"
    t.string "device_name"
    t.string "device_os"
    t.string "device_id"
    t.integer "connection_type"
  end

  create_table "office_exclude_dates", force: :cascade do |t|
    t.bigint "office_id"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_id"], name: "index_office_exclude_dates_on_office_id"
  end

  create_table "office_pocs", force: :cascade do |t|
    t.bigint "office_id"
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "status", default: 1
    t.boolean "primary"
    t.index ["office_id"], name: "index_office_pocs_on_office_id"
  end

  create_table "office_referrals", force: :cascade do |t|
    t.bigint "office_id"
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.integer "created_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_id"], name: "index_office_referrals_on_office_id"
  end

  create_table "office_restaurant_exclusions", force: :cascade do |t|
    t.bigint "office_id"
    t.bigint "restaurant_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_id"], name: "index_office_restaurant_exclusions_on_office_id"
    t.index ["restaurant_id"], name: "index_office_restaurant_exclusions_on_restaurant_id"
  end

  create_table "offices", force: :cascade do |t|
    t.integer "status", default: 1
    t.string "name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.integer "total_staff_count"
    t.string "office_policy"
    t.string "food_preferences"
    t.string "delivery_instructions"
    t.string "specialty"
    t.string "timezone"
    t.date "appointments_until"
    t.integer "creating_sales_rep_id"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "policies_last_updated_at"
    t.datetime "activated_at"
    t.integer "activated_by_id"
    t.datetime "deactivated_at"
    t.integer "deactivated_by_id"
    t.string "phone"
    t.string "passcode"
    t.boolean "passcode_active", default: false, null: false
    t.boolean "internal", default: true, null: false
    t.string "logo_image"
  end

  create_table "offices_providers", id: false, force: :cascade do |t|
    t.bigint "office_id", null: false
    t.bigint "provider_id", null: false
    t.integer "created_by_id"
    t.index ["office_id", "provider_id"], name: "index_offices_providers_on_office_id_and_provider_id"
    t.index ["provider_id", "office_id"], name: "index_offices_providers_on_provider_id_and_office_id"
  end

  create_table "offices_sales_reps", force: :cascade do |t|
    t.bigint "office_id"
    t.bigint "sales_rep_id"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "per_person_budget_cents"
    t.string "notes"
    t.integer "created_by_id"
    t.string "office_notes"
    t.integer "listed_type", default: 0, null: false
    t.index ["office_id"], name: "index_offices_sales_reps_on_office_id"
    t.index ["sales_rep_id"], name: "index_offices_sales_reps_on_sales_rep_id"
  end

  create_table "order_reviews", force: :cascade do |t|
    t.bigint "order_id"
    t.string "title"
    t.integer "food_quality"
    t.integer "presentation"
    t.integer "completion"
    t.boolean "on_time"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reviewer_id"
    t.integer "created_by_id"
    t.string "reviewer_type"
    t.integer "status"
    t.integer "overall"
    t.index ["order_id"], name: "index_order_reviews_on_order_id"
  end

  create_table "order_transactions", force: :cascade do |t|
    t.bigint "payment_method_id"
    t.bigint "order_id"
    t.bigint "authorized_amount_cents"
    t.bigint "captured_amount_cents"
    t.string "transaction_identifier"
    t.integer "status"
    t.string "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "raw_api_response"
    t.integer "transaction_type"
    t.bigint "refunded_amount_cents"
    t.index ["order_id"], name: "index_order_transactions_on_order_id"
    t.index ["payment_method_id"], name: "index_order_transactions_on_payment_method_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "sales_rep_id"
    t.bigint "appointment_id"
    t.bigint "restaurant_id"
    t.string "order_number"
    t.string "rep_notes"
    t.string "restaurant_notes"
    t.integer "subtotal_cents"
    t.integer "sales_tax_cents"
    t.integer "delivery_cost_cents"
    t.bigint "lunchpro_commission_cents"
    t.integer "processing_fee_cents"
    t.integer "tip_cents"
    t.integer "total_cents"
    t.boolean "funds_reserved"
    t.boolean "funds_funded"
    t.bigint "created_by_user_id"
    t.string "driver_name"
    t.string "driver_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.uuid "idempotency_key"
    t.boolean "withhold_tip", default: false, null: false
    t.integer "restaurant_transaction_id"
    t.datetime "delivered_at"
    t.datetime "delivery_arrived_at"
    t.datetime "completed_at"
    t.integer "estimated_tip_cents"
    t.integer "payment_method_id"
    t.integer "recommended_by_id"
    t.string "office_notes"
    t.integer "updated_by_id"
    t.datetime "cancelled_at"
    t.integer "cancelled_by_id"
    t.index ["appointment_id"], name: "index_orders_on_appointment_id"
    t.index ["created_by_user_id"], name: "index_orders_on_created_by_user_id"
    t.index ["order_number"], name: "index_orders_on_order_number"
    t.index ["restaurant_id"], name: "index_orders_on_restaurant_id"
    t.index ["sales_rep_id"], name: "index_orders_on_sales_rep_id"
  end

  create_table "payment_methods", force: :cascade do |t|
    t.bigint "user_id"
    t.string "stripe_identifier"
    t.integer "last_four"
    t.integer "cc_type"
    t.integer "sort_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "expire_month"
    t.integer "expire_year"
    t.integer "status", default: 1
    t.string "cardholder_name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "nickname"
    t.index ["status"], name: "index_payment_methods_on_status"
    t.index ["user_id"], name: "index_payment_methods_on_user_id"
  end

  create_table "provider_availabilities", force: :cascade do |t|
    t.bigint "provider_id"
    t.integer "day_of_week"
    t.time "starts_at"
    t.time "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
    t.integer "created_by_id"
    t.index ["provider_id"], name: "index_provider_availabilities_on_provider_id"
  end

  create_table "provider_exclude_dates", force: :cascade do |t|
    t.bigint "provider_id"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_exclude_dates_on_provider_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1
    t.text "specialties", default: [], array: true
  end

  create_table "restaurant_availabilities", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.integer "day_of_week"
    t.time "starts_at"
    t.time "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.index ["restaurant_id"], name: "index_restaurant_availabilities_on_restaurant_id"
  end

  create_table "restaurant_exclude_dates", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_id"], name: "index_restaurant_exclude_dates_on_restaurant_id"
  end

  create_table "restaurant_pocs", force: :cascade do |t|
    t.bigint "restaurant_id"
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.string "phone"
    t.string "email"
    t.integer "created_by_id"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "primary", default: false
    t.index ["restaurant_id"], name: "index_restaurant_pocs_on_restaurant_id"
  end

  create_table "restaurant_transactions", force: :cascade do |t|
    t.integer "bank_account_id"
    t.integer "restaurant_id"
    t.integer "due_amount_cents"
    t.integer "paid_amount_cents"
    t.integer "status", default: 1
    t.string "notes"
    t.integer "created_by_id"
    t.integer "processed_by_id"
    t.integer "cancelled_by_id"
    t.datetime "processed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "restaurants", force: :cascade do |t|
    t.integer "status", default: 1
    t.string "name"
    t.string "description"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.bigint "min_order_amount_cents"
    t.integer "max_order_people"
    t.bigint "default_delivery_fee_cents"
    t.integer "orders_until_hour"
    t.string "timezone"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "latitude"
    t.float "longitude"
    t.integer "orders_until"
    t.boolean "withhold_tip", default: false, null: false
    t.boolean "withhold_tax", default: false, null: false
    t.integer "processing_fee_type", default: 10
    t.integer "processing_fee_percent"
    t.datetime "deactivated_at"
    t.datetime "activated_at"
    t.integer "late_cancel_fee_cents"
    t.integer "person_price_low"
    t.integer "person_price_high"
    t.string "brand_image"
    t.string "phone"
    t.string "stripe_account"
    t.integer "headquarters_id"
    t.integer "deactivated_by_id"
    t.integer "sales_tax_percent", default: 825, null: false
    t.integer "cancel_until_hours", default: 24, null: false
    t.integer "edit_until_hours", default: 6, null: false
    t.integer "wholesale_percentage", default: 2000, null: false
    t.index ["stripe_account"], name: "index_restaurants_on_stripe_account"
  end

  create_table "sales_rep_emails", force: :cascade do |t|
    t.bigint "sales_rep_id"
    t.string "email_address"
    t.integer "email_type", default: 2, null: false
    t.integer "status"
    t.integer "notification_preference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.index ["sales_rep_id"], name: "index_sales_rep_emails_on_sales_rep_id"
  end

  create_table "sales_rep_partners", force: :cascade do |t|
    t.bigint "sales_rep_id"
    t.integer "partner_id"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.index ["partner_id"], name: "index_sales_rep_partners_on_partner_id"
    t.index ["sales_rep_id"], name: "index_sales_rep_partners_on_sales_rep_id"
  end

  create_table "sales_rep_phones", force: :cascade do |t|
    t.bigint "sales_rep_id"
    t.string "phone_number"
    t.integer "phone_type", default: 2, null: false
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.integer "notification_preference"
    t.index ["sales_rep_id"], name: "index_sales_rep_phones_on_sales_rep_id"
  end

  create_table "sales_reps", force: :cascade do |t|
    t.integer "status", default: 1
    t.integer "user_id"
    t.string "first_name"
    t.string "last_name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "address_line3"
    t.string "city"
    t.string "state"
    t.string "postal_code"
    t.string "country"
    t.integer "company_id"
    t.integer "default_tip_percent"
    t.bigint "max_tip_amount_cents"
    t.bigint "per_person_budget_cents"
    t.string "timezone"
    t.integer "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "profile_image"
    t.datetime "activated_at"
    t.datetime "deactivated_at"
    t.integer "reward_points", default: 0, null: false
    t.datetime "last_reward_date"
    t.text "specialties", default: [], array: true
    t.index ["company_id"], name: "index_sales_reps_on_company_id"
    t.index ["user_id"], name: "index_sales_reps_on_user_id"
  end

  create_table "sample_requests", force: :cascade do |t|
    t.bigint "appointment_id"
    t.bigint "drug_id"
    t.string "note"
    t.boolean "fulfilled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_sample_requests_on_appointment_id"
    t.index ["drug_id"], name: "index_sample_requests_on_drug_id"
  end

  create_table "user_access_tokens", force: :cascade do |t|
    t.integer "user_id"
    t.string "access_token"
    t.integer "status", default: 1
    t.string "message"
    t.datetime "last_accessed_at"
    t.string "last_accessed_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_devices", force: :cascade do |t|
    t.integer "user_id"
    t.integer "status", default: 1
    t.string "token"
    t.string "arn"
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_notification_prefs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "status", default: 1
    t.string "notifiable_type"
    t.integer "notifiable_id"
    t.jsonb "via_email"
    t.jsonb "via_sms"
    t.jsonb "via_push"
    t.integer "last_updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_offices", force: :cascade do |t|
    t.integer "user_id"
    t.integer "office_id"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.index ["office_id", "user_id"], name: "index_user_offices_on_office_id_and_user_id"
    t.index ["user_id", "office_id"], name: "index_user_offices_on_user_id_and_office_id"
  end

  create_table "user_restaurants", force: :cascade do |t|
    t.integer "user_id"
    t.integer "restaurant_id"
    t.integer "status", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "created_by_id"
    t.index ["restaurant_id", "user_id"], name: "index_user_restaurants_on_restaurant_id_and_user_id"
    t.index ["user_id", "restaurant_id"], name: "index_user_restaurants_on_user_id_and_restaurant_id"
  end

  create_table "user_searches", force: :cascade do |t|
    t.integer "user_id"
    t.integer "status", default: 1
    t.string "search_type"
    t.string "search_model"
    t.jsonb "conditions"
    t.string "name"
    t.datetime "saved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "primary_phone"
    t.integer "space", default: 1
    t.integer "status", default: 1
    t.datetime "validated_at"
    t.integer "validated_by_id"
    t.datetime "last_modified_at"
    t.integer "last_modified_by_id"
    t.datetime "deactivated_at"
    t.string "timezone"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.bigint "invited_by_id"
    t.integer "invitations_count", default: 0
    t.string "stripe_customer"
    t.boolean "is_internal", default: false, null: false
    t.string "job_title"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer "deactivated_by_id"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["stripe_customer"], name: "index_users_on_stripe_customer"
  end

end
