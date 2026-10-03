# A login session for the API. The client gets a random token once, at login, and sends
# it on every request as "Authorization: Bearer <token>".
#
# Only a SHA-256 digest of the token is stored, so a leaked database doesn't leak working
# tokens. SHA-256 (fast) is fine here, unlike for passwords (bcrypt, slow): a 32-character
# random token can't be guessed by brute force, and a fast digest lets us look it up by index.
class ApiToken < ApplicationRecord
  LIFETIME = 30.days

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  # Creates a token for the user and returns the raw token string.
  # This is the only moment the raw token exists; it is never stored.
  def self.issue_for(user)
    raw_token = SecureRandom.base58(32)
    create!(user: user, token_digest: digest(raw_token), expires_at: LIFETIME.from_now)
    raw_token
  end

  # Finds the unexpired token record matching a raw token from a request, or nil.
  def self.find_active(raw_token)
    active.find_by(token_digest: digest(raw_token))
  end

  def self.digest(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token)
  end

  # Records usage at most once a minute, so busy clients don't cause a write per request.
  def touch_last_used!
    update_column(:last_used_at, Time.current) if last_used_at.nil? || last_used_at < 1.minute.ago
  end
end
