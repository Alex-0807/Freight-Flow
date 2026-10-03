class CustomerSerializer < BaseSerializer
  def self.call(customer)
    {
      id: customer.id,
      name: customer.name,
      code: customer.code,
      rate_card: customer.rate_card && { id: customer.rate_card.id, name: customer.rate_card.name }
    }
  end
end
