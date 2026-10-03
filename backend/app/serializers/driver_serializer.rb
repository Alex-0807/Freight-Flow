class DriverSerializer < BaseSerializer
  # active_jobs_count is only present when the query selected it (DriversController#index).
  def self.call(driver)
    {
      id: driver.id,
      name: driver.name,
      phone: driver.phone,
      vehicle_registration: driver.vehicle_registration,
      active: driver.active,
      active_jobs_count: driver.has_attribute?(:active_jobs_count) ? driver.active_jobs_count : nil
    }
  end
end
