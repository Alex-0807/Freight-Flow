class CreateProofOfDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :proof_of_deliveries do |t|
      # unique: one POD per consignment, enforced by the database even under concurrency.
      t.references :consignment, null: false, foreign_key: true, index: { unique: true }
      t.string :receiver_name, null: false
      t.datetime :delivered_at, null: false
      t.text :notes
      t.timestamps
    end
  end
end
