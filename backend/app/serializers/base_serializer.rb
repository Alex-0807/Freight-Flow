# Shared formatting for all serializers. A serializer turns a record into a plain Hash,
# and the controller renders that Hash as JSON.
#
# Money and measurements are sent as strings ("328.25", not 328.25). JSON numbers are
# floating point in most clients (Dart parses 328.25 as a double), so strings are the only
# way to hand exact decimals to the Flutter app.
class BaseSerializer
  def self.money(amount)
    decimal(amount, 2)
  end

  def self.decimal(amount, places)
    return nil if amount.nil?

    ActiveSupport::NumberHelper.number_to_rounded(amount, precision: places)
  end

  # ISO 8601 with offset, e.g. "2026-10-03T14:05:00+10:00". Clients convert to local time.
  def self.time(value)
    value&.iso8601
  end
end
