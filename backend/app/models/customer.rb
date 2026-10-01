class Customer < ApplicationRecord
  # optional: true because a customer without a card falls back to the default card.
  belongs_to :rate_card, optional: true
  has_many :consignments, dependent: :restrict_with_exception
  has_many :invoices, dependent: :restrict_with_exception

  normalizes :code, with: ->(code) { code.strip.upcase }
  normalizes :billing_email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
  validates :billing_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
