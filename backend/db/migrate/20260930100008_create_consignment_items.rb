class CreateConsignmentItems < ActiveRecord::Migration[8.1]
  def change
    create_table :consignment_items do |t|
      t.references :consignment, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :quantity, null: false
      t.decimal :weight_kg, precision: 10, scale: 3, null: false # per unit
      t.integer :length_cm, null: false
      t.integer :width_cm, null: false
      t.integer :height_cm, null: false
      t.timestamps

      t.check_constraint "quantity > 0", name: "consignment_items_quantity_positive"
      t.check_constraint "weight_kg > 0", name: "consignment_items_weight_positive"
      t.check_constraint "length_cm > 0 AND width_cm > 0 AND height_cm > 0",
        name: "consignment_items_dimensions_positive"
    end
  end
end
