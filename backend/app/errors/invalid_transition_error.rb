# Raised when a consignment is asked to move to a status the lifecycle doesn't allow,
# e.g. booked -> delivered.
class InvalidTransitionError < DomainError
  attr_reader :from, :to

  def initialize(from:, to:)
    @from = from.to_s
    @to = to.to_s
    super("Cannot change consignment status from #{@from} to #{@to}")
  end
end
