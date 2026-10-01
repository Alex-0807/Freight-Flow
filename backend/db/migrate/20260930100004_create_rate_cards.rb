class CreateRateCards < ActiveRecord::Migration[8.1]
  def change
    create_table :rate_cards do |t|
      t.string :name, null: false
      t.boolean :is_default, null: false, default: false
      t.decimal :base_charge, precision: 10, scale: 2, null: false
      t.decimal :minimum_charge, precision: 10, scale: 2, null: false
      t.decimal :fuel_levy_percent, precision: 5, scale: 2, null: false
      t.integer :cubic_conversion_factor, null: false, default: 250
      t.timestamps

      t.index :name, unique: true
      # Partial unique index: only rows WHERE is_default are indexed,
      # so at most one row can have is_default = true.
      t.index :is_default, unique: true, where: "is_default", name: "index_rate_cards_one_default"

      t.check_constraint "base_charge >= 0", name: "rate_cards_base_charge_non_negative"
      t.check_constraint "minimum_charge >= 0", name: "rate_cards_minimum_charge_non_negative"
      t.check_constraint "fuel_levy_percent >= 0", name: "rate_cards_fuel_levy_non_negative"
      t.check_constraint "cubic_conversion_factor > 0", name: "rate_cards_cubic_factor_positive"
    end
  end
end
