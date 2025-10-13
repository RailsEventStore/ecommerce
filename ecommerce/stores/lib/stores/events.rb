module Stores

  class StoreRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
  end

  class StoreNamed < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

  class ProductRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

end
