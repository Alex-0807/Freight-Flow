class CreateDrivers < ActiveRecord::Migration[8.1]
  def change
    create_table :drivers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :phone, null: false
      t.string :vehicle_registration, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
