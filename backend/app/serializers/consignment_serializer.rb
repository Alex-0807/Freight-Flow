# The database stores addresses as flat columns (pickup_suburb, ...); the API nests them
# (pickup: { suburb: ... }). The API shape is designed for clients, not copied from the table.
#
# List responses use the summary; detail responses add items, POD and invoice.
# Callers must preload what's used here (see ConsignmentsController) to avoid N+1 queries.
class ConsignmentSerializer < BaseSerializer
  def self.summary(consignment)
    {
      id: consignment.id,
      reference: consignment.reference,
      status: consignment.status,
      customer: { id: consignment.customer.id, name: consignment.customer.name, code: consignment.customer.code },
      driver: consignment.driver && { id: consignment.driver.id, name: consignment.driver.name },
      pickup: address(consignment, :pickup),
      delivery: address(consignment, :delivery).merge(instructions: consignment.delivery_instructions),
      requested_delivery_date: consignment.requested_delivery_date.iso8601,
      total_items: consignment.total_items,
      total_weight_kg: decimal(consignment.total_weight_kg, 3),
      total_volume_m3: decimal(consignment.total_volume_m3, 3),
      total_charge: money(consignment.total_charge),
      created_at: time(consignment.created_at),
      updated_at: time(consignment.updated_at)
    }
  end

  def self.detail(consignment)
    summary(consignment).merge(
      items: consignment.consignment_items.map { |item| item_json(item) },
      pricing: {
        rate_card: { id: consignment.rate_card.id, name: consignment.rate_card.name },
        chargeable_weight_kg: decimal(consignment.chargeable_weight_kg, 3),
        freight_charge: money(consignment.freight_charge),
        fuel_levy_percent: decimal(consignment.fuel_levy_percent, 2),
        fuel_levy_amount: money(consignment.fuel_levy_amount),
        total_charge: money(consignment.total_charge)
      },
      proof_of_delivery: consignment.proof_of_delivery && {
        receiver_name: consignment.proof_of_delivery.receiver_name,
        delivered_at: time(consignment.proof_of_delivery.delivered_at),
        notes: consignment.proof_of_delivery.notes
      },
      invoice: consignment.invoice && {
        id: consignment.invoice.id,
        invoice_number: consignment.invoice.invoice_number,
        total_amount: money(consignment.invoice.total_amount)
      }
    )
  end

  def self.address(consignment, prefix)
    {
      address_line1: consignment.public_send("#{prefix}_address_line1"),
      suburb: consignment.public_send("#{prefix}_suburb"),
      state: consignment.public_send("#{prefix}_state"),
      postcode: consignment.public_send("#{prefix}_postcode")
    }
  end

  def self.item_json(item)
    {
      id: item.id,
      description: item.description,
      quantity: item.quantity,
      weight_kg: decimal(item.weight_kg, 3),
      length_cm: item.length_cm,
      width_cm: item.width_cm,
      height_cm: item.height_cm
    }
  end
end
