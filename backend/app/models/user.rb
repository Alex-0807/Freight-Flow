class User < ApplicationRecord
  # Adds `password` / `password_confirmation` attributes, stores a bcrypt hash in
  # password_digest, and gives us `user.authenticate("secret")`.
  has_secure_password

  has_one :driver_profile, class_name: "Driver", dependent: :restrict_with_exception
  has_many :api_tokens, dependent: :delete_all

  # Stored as readable strings ("dispatcher"), never as integers.
  # Gives user.dispatcher?, user.driver?, User.dispatcher (a scope), etc.
  # validate: true turns an unknown role into a validation error instead of an exception.
  enum :role, { dispatcher: "dispatcher", driver: "driver" }, validate: true

  # Runs before validation and before queries: " Mia@Example.COM " -> "mia@example.com",
  # so the unique index can't be dodged by capital letters.
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
