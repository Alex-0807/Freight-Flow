module Consignments
  # What every consignment action returns.
  #   changed? == true  -> this call changed the consignment
  #   changed? == false -> it was already in the requested state (a retry); nothing was written
  # Deliver uses changed? to enqueue invoice/notification jobs only once (Step 8).
  Result = Data.define(:consignment, :changed) do
    def changed? = changed
  end
end
