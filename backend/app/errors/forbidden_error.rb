# Raised when the logged-in user isn't allowed to do something, e.g. a driver trying to
# book a consignment, or opening another driver's job. Becomes HTTP 403.
class ForbiddenError < StandardError
  def initialize(message = "You are not allowed to do that")
    super
  end
end
