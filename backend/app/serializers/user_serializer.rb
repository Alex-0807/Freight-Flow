class UserSerializer < BaseSerializer
  def self.call(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      driver_id: user.driver_profile&.id # set for drivers, so the app can load "my jobs"
    }
  end
end
