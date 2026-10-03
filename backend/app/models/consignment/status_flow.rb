class Consignment
  # The consignment lifecycle as plain data: which status may follow which.
  #
  #   booked -> allocated -> picked_up -> in_transit -> delivered
  #
  # This is the whole state machine. It has no database access and no side effects,
  # so it is trivial to test and to extend (e.g. add "cancelled" with one line).
  module StatusFlow
    TRANSITIONS = {
      "booked" => %w[allocated],
      "allocated" => %w[picked_up],
      "picked_up" => %w[in_transit],
      "in_transit" => %w[delivered],
      "delivered" => []
    }.freeze   #freeze means the hash cannot be modified at runtime.

    def self.allowed?(from, to)
      TRANSITIONS.fetch(from.to_s, []).include?(to.to_s)
    end

    def self.assert!(from, to)
      raise InvalidTransitionError.new(from: from, to: to) unless allowed?(from, to)
    end
  end
end
