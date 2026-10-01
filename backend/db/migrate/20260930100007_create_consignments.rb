class CreateConsignments < ActiveRecord::Migration[8.1]
  def change
    create_table :consignments do |t|
      # index: false on customer and driver: the composite indexes below start with
      # those columns, so separate single-column indexes would be redundant.
      t.references :customer, null: false, foreign_key: true, index: false
      t.references :driver, foreign_key: true, index: false # NULL until allocated
      t.references :rate_card, null: false, foreign_key: true

      t.string :reference, null: false
      t.string :status, null: false, default: "booked"

      # Addresses are a snapshot of this booking, not links to a shared address table.
      t.string :pickup_address_line1, null: false
      t.string :pickup_suburb, null: false
      t.string :pickup_state, null: false
      t.string :pickup_postcode, null: false
      t.string :delivery_address_line1, null: false
      t.string :delivery_suburb, null: false
      t.string :delivery_state, null: false
      t.string :delivery_postcode, null: false
      t.text :delivery_instructions
      t.date :requested_delivery_date, null: false

      # Totals, stored because the price was calculated from exactly these numbers.
      t.integer :total_items, null: false
      t.decimal :total_weight_kg, precision: 10, scale: 3, null: false
      t.decimal :total_volume_m3, precision: 10, scale: 3, null: false

      # Price snapshot, taken at booking time.
      t.decimal :chargeable_weight_kg, precision: 10, scale: 3, null: false
      t.decimal :freight_charge, precision: 12, scale: 2, null: false
      t.decimal :fuel_levy_percent, precision: 5, scale: 2, null: false
      t.decimal :fuel_levy_amount, precision: 12, scale: 2, null: false
      t.decimal :total_charge, precision: 12, scale: 2, null: false

      t.datetime :delivery_notified_at
      t.timestamps

      t.index %i[customer_id reference], unique: true
      t.index %i[driver_id status]
      t.index :status

      # Written out literally on purpose: a migration must describe the schema as it
      # was at this point in time, so it never references model constants that may change.
      t.check_constraint "status IN ('booked', 'allocated', 'picked_up', 'in_transit', 'delivered')",
        name: "consignments_status_valid"
      t.check_constraint "total_items > 0", name: "consignments_total_items_positive"
      t.check_constraint "total_weight_kg > 0", name: "consignments_total_weight_positive"
      t.check_constraint "total_volume_m3 >= 0", name: "consignments_total_volume_non_negative"
      t.check_constraint "chargeable_weight_kg > 0", name: "consignments_chargeable_weight_positive"
      t.check_constraint "freight_charge >= 0", name: "consignments_freight_charge_non_negative"
      t.check_constraint "fuel_levy_percent >= 0", name: "consignments_fuel_levy_percent_non_negative"
      t.check_constraint "fuel_levy_amount >= 0", name: "consignments_fuel_levy_amount_non_negative"
      t.check_constraint "total_charge = freight_charge + fuel_levy_amount",
        name: "consignments_total_charge_matches"
    end
  end
end
