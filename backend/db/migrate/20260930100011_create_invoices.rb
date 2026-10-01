class CreateInvoices < ActiveRecord::Migration[8.1]
  def change
    create_table :invoices do |t|
      # unique: one invoice per consignment. This index is what makes invoice
      # generation idempotent: a second INSERT for the same consignment fails.
      t.references :consignment, null: false, foreign_key: true, index: { unique: true }
      t.references :customer, null: false, foreign_key: true
      t.decimal :freight_charge, precision: 12, scale: 2, null: false
      t.decimal :fuel_levy_amount, precision: 12, scale: 2, null: false
      t.decimal :total_amount, precision: 12, scale: 2, null: false
      t.datetime :issued_at, null: false
      t.timestamps

      # PostgreSQL computes the number from the row's own id (e.g. id 42 -> INV-000042).
      # The id comes from a sequence, so two concurrent inserts can never get the same
      # number, and Ruby code can never forget to set it.
      t.virtual :invoice_number, type: :string, stored: true,
        as: "'INV-' || lpad(id::text, 6, '0')"
      t.index :invoice_number, unique: true

      t.check_constraint "freight_charge >= 0", name: "invoices_freight_charge_non_negative"
      t.check_constraint "fuel_levy_amount >= 0", name: "invoices_fuel_levy_amount_non_negative"
      t.check_constraint "total_amount = freight_charge + fuel_levy_amount",
        name: "invoices_total_amount_matches"
    end
  end
end
