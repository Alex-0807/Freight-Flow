class Driver < ApplicationRecord
  belongs_to :user
  has_many :consignments, dependent: :restrict_with_exception

  scope :active, -> { where(active: true) }

  # driver.name reads through to driver.user.name.
  delegate :name, :email, to: :user

  validates :phone, :vehicle_registration, presence: true
  validates :user_id, uniqueness: true
  validate :user_must_have_driver_role

  private

  def user_must_have_driver_role
    errors.add(:user, "must have the driver role") if user && !user.driver?
  end
end
