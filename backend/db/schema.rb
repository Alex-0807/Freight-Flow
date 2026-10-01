# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_30_100011) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "consignment_items", force: :cascade do |t|
    t.bigint "consignment_id", null: false
    t.string "description", null: false
    t.integer "quantity", null: false
    t.decimal "weight_kg", precision: 10, scale: 3, null: false
    t.integer "length_cm", null: false
    t.integer "width_cm", null: false
    t.integer "height_cm", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consignment_id"], name: "index_consignment_items_on_consignment_id"
    t.check_constraint "length_cm > 0 AND width_cm > 0 AND height_cm > 0", name: "consignment_items_dimensions_positive"
    t.check_constraint "quantity > 0", name: "consignment_items_quantity_positive"
    t.check_constraint "weight_kg > 0::numeric", name: "consignment_items_weight_positive"
  end

  create_table "consignments", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "driver_id"
    t.bigint "rate_card_id", null: false
    t.string "reference", null: false
    t.string "status", default: "booked", null: false
    t.string "pickup_address_line1", null: false
    t.string "pickup_suburb", null: false
    t.string "pickup_state", null: false
    t.string "pickup_postcode", null: false
    t.string "delivery_address_line1", null: false
    t.string "delivery_suburb", null: false
    t.string "delivery_state", null: false
    t.string "delivery_postcode", null: false
    t.text "delivery_instructions"
    t.date "requested_delivery_date", null: false
    t.integer "total_items", null: false
    t.decimal "total_weight_kg", precision: 10, scale: 3, null: false
    t.decimal "total_volume_m3", precision: 10, scale: 3, null: false
    t.decimal "chargeable_weight_kg", precision: 10, scale: 3, null: false
    t.decimal "freight_charge", precision: 12, scale: 2, null: false
    t.decimal "fuel_levy_percent", precision: 5, scale: 2, null: false
    t.decimal "fuel_levy_amount", precision: 12, scale: 2, null: false
    t.decimal "total_charge", precision: 12, scale: 2, null: false
    t.datetime "delivery_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "reference"], name: "index_consignments_on_customer_id_and_reference", unique: true
    t.index ["driver_id", "status"], name: "index_consignments_on_driver_id_and_status"
    t.index ["rate_card_id"], name: "index_consignments_on_rate_card_id"
    t.index ["status"], name: "index_consignments_on_status"
    t.check_constraint "chargeable_weight_kg > 0::numeric", name: "consignments_chargeable_weight_positive"
    t.check_constraint "freight_charge >= 0::numeric", name: "consignments_freight_charge_non_negative"
    t.check_constraint "fuel_levy_amount >= 0::numeric", name: "consignments_fuel_levy_amount_non_negative"
    t.check_constraint "fuel_levy_percent >= 0::numeric", name: "consignments_fuel_levy_percent_non_negative"
    t.check_constraint "status::text = ANY (ARRAY['booked'::character varying, 'allocated'::character varying, 'picked_up'::character varying, 'in_transit'::character varying, 'delivered'::character varying]::text[])", name: "consignments_status_valid"
    t.check_constraint "total_charge = (freight_charge + fuel_levy_amount)", name: "consignments_total_charge_matches"
    t.check_constraint "total_items > 0", name: "consignments_total_items_positive"
    t.check_constraint "total_volume_m3 >= 0::numeric", name: "consignments_total_volume_non_negative"
    t.check_constraint "total_weight_kg > 0::numeric", name: "consignments_total_weight_positive"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "billing_email", null: false
    t.bigint "rate_card_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_customers_on_code", unique: true
    t.index ["rate_card_id"], name: "index_customers_on_rate_card_id"
  end

  create_table "drivers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "phone", null: false
    t.string "vehicle_registration", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_drivers_on_user_id", unique: true
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "consignment_id", null: false
    t.bigint "customer_id", null: false
    t.decimal "freight_charge", precision: 12, scale: 2, null: false
    t.decimal "fuel_levy_amount", precision: 12, scale: 2, null: false
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.datetime "issued_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.virtual "invoice_number", type: :string, as: "('INV-'::text || lpad((id)::text, 6, '0'::text))", stored: true
    t.index ["consignment_id"], name: "index_invoices_on_consignment_id", unique: true
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.check_constraint "freight_charge >= 0::numeric", name: "invoices_freight_charge_non_negative"
    t.check_constraint "fuel_levy_amount >= 0::numeric", name: "invoices_fuel_levy_amount_non_negative"
    t.check_constraint "total_amount = (freight_charge + fuel_levy_amount)", name: "invoices_total_amount_matches"
  end

  create_table "proof_of_deliveries", force: :cascade do |t|
    t.bigint "consignment_id", null: false
    t.string "receiver_name", null: false
    t.datetime "delivered_at", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consignment_id"], name: "index_proof_of_deliveries_on_consignment_id", unique: true
  end

  create_table "rate_cards", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "is_default", default: false, null: false
    t.decimal "base_charge", precision: 10, scale: 2, null: false
    t.decimal "minimum_charge", precision: 10, scale: 2, null: false
    t.decimal "fuel_levy_percent", precision: 5, scale: 2, null: false
    t.integer "cubic_conversion_factor", default: 250, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_default"], name: "index_rate_cards_one_default", unique: true, where: "is_default"
    t.index ["name"], name: "index_rate_cards_on_name", unique: true
    t.check_constraint "base_charge >= 0::numeric", name: "rate_cards_base_charge_non_negative"
    t.check_constraint "cubic_conversion_factor > 0", name: "rate_cards_cubic_factor_positive"
    t.check_constraint "fuel_levy_percent >= 0::numeric", name: "rate_cards_fuel_levy_non_negative"
    t.check_constraint "minimum_charge >= 0::numeric", name: "rate_cards_minimum_charge_non_negative"
  end

  create_table "rate_rules", force: :cascade do |t|
    t.bigint "rate_card_id", null: false
    t.decimal "min_weight_kg", precision: 10, scale: 3, null: false
    t.decimal "per_kg_rate", precision: 10, scale: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rate_card_id", "min_weight_kg"], name: "index_rate_rules_on_rate_card_id_and_min_weight_kg", unique: true
    t.check_constraint "min_weight_kg >= 0::numeric", name: "rate_rules_min_weight_non_negative"
    t.check_constraint "per_kg_rate >= 0::numeric", name: "rate_rules_per_kg_rate_non_negative"
  end

  create_table "tracking_events", force: :cascade do |t|
    t.bigint "consignment_id", null: false
    t.bigint "user_id"
    t.string "event_type", null: false
    t.string "status", null: false
    t.datetime "occurred_at", null: false
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["consignment_id", "occurred_at"], name: "index_tracking_events_on_consignment_id_and_occurred_at"
    t.index ["user_id"], name: "index_tracking_events_on_user_id"
    t.check_constraint "(latitude IS NULL) = (longitude IS NULL)", name: "tracking_events_coordinates_paired"
    t.check_constraint "event_type::text = ANY (ARRAY['status_changed'::character varying, 'driver_reassigned'::character varying]::text[])", name: "tracking_events_event_type_valid"
    t.check_constraint "latitude >= '-90'::integer::numeric AND latitude <= 90::numeric", name: "tracking_events_latitude_range"
    t.check_constraint "longitude >= '-180'::integer::numeric AND longitude <= 180::numeric", name: "tracking_events_longitude_range"
    t.check_constraint "status::text = ANY (ARRAY['booked'::character varying, 'allocated'::character varying, 'picked_up'::character varying, 'in_transit'::character varying, 'delivered'::character varying]::text[])", name: "tracking_events_status_valid"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "role::text = ANY (ARRAY['dispatcher'::character varying, 'driver'::character varying]::text[])", name: "users_role_valid"
  end

  add_foreign_key "api_tokens", "users", on_delete: :cascade
  add_foreign_key "consignment_items", "consignments"
  add_foreign_key "consignments", "customers"
  add_foreign_key "consignments", "drivers"
  add_foreign_key "consignments", "rate_cards"
  add_foreign_key "customers", "rate_cards"
  add_foreign_key "drivers", "users"
  add_foreign_key "invoices", "consignments"
  add_foreign_key "invoices", "customers"
  add_foreign_key "proof_of_deliveries", "consignments"
  add_foreign_key "rate_rules", "rate_cards"
  add_foreign_key "tracking_events", "consignments"
  add_foreign_key "tracking_events", "users"
end
