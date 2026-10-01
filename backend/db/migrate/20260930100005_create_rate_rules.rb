class CreateRateRules < ActiveRecord::Migration[8.1]
  def change
    create_table :rate_rules do |t|
      # index: false because the composite unique index below starts with rate_card_id
      # and already serves "find rules for this card" lookups.
      t.references :rate_card, null: false, foreign_key: true, index: false
      t.decimal :min_weight_kg, precision: 10, scale: 3, null: false
      t.decimal :per_kg_rate, precision: 10, scale: 4, null: false
      t.timestamps

      t.index %i[rate_card_id min_weight_kg], unique: true
      t.check_constraint "min_weight_kg >= 0", name: "rate_rules_min_weight_non_negative"
      t.check_constraint "per_kg_rate >= 0", name: "rate_rules_per_kg_rate_non_negative"
    end
  end
end
