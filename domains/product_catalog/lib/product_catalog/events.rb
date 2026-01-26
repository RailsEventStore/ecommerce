module ProductCatalog

  class ProductRegistered < Infra::Event
    attribute :product_id, Infra::Types::UUID
  end

  class ProductNamed < Infra::Event
    attribute :product_id, Infra::Types::String
  end

end
