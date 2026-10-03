# Raised when a shipment can't be priced: the customer has no rate card and there is no
# default card, or no weight tier on the card covers the shipment.
class PricingUnavailableError < DomainError
end
