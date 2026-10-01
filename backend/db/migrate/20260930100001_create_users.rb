class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false
      t.timestamps

      t.index :email, unique: true
      t.check_constraint "role IN ('dispatcher', 'driver')", name: "users_role_valid"
    end
  end
end
