module ProductCatalog

  class ProductRegistered < Infra::Event
    attribute :product_id, Infra::Types::UUID
  end

  class ProductNamed < Infra::Event
    attribute :product_id, Infra::Types::String
  end

  class ProductNameChangeRequested < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

  class ProductNameApproved < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

  class ProductNameRejected < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

end
