# Raised when a dispatcher tries to assign a job to a driver who is not active.
class DriverUnavailableError < DomainError
  def initialize(driver)
    super("Driver #{driver.name} is not active and can't be assigned jobs")
  end
end
