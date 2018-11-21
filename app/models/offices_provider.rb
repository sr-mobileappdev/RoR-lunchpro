class OfficesProvider < ApplicationRecord
  # Join table only, no update columns or status, see providers for creating user and status

  # Per dnovak: And a provider can only be associated with 1 office at a time, so if a Dr actually worked at 2..  then there would be 2 listings for that Dr. The system would have no idea it's the same provider
  # Providers at more than one office is NOT supported. They would become a unique provider per office
  belongs_to :office
  belongs_to :provider

end
