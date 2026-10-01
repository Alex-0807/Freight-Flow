class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :billing_email, null: false
      # NULL means "use the default rate card".
      t.references :rate_card, foreign_key: true
      t.timestamps

      t.index :code, unique: true
    end
  end
end
