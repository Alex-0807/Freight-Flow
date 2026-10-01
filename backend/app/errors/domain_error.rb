# Base class for business-rule failures ("you can't do that right now"), as opposed to
# bugs or infrastructure errors. Step 6 turns every DomainError into a JSON error response.
class DomainError < StandardError
end
