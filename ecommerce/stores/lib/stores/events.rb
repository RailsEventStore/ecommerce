module Stores

  class StoreRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
  end

end
