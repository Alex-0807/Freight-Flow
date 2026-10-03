module Pricing
  # Decides which rate card prices a customer's freight:
  # the customer's own card, otherwise the default card, otherwise an error.
  class RateCardResolver
    def self.call(customer)
      customer.rate_card ||
        RateCard.default_card ||
        raise(PricingUnavailableError, "No rate card for customer #{customer.code} and no default rate card")
    end
  end
end
