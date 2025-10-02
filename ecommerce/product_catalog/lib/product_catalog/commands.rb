module ProductCatalog
  class RegisterProduct < Infra::Command
    attribute :product_id, Infra::Types::UUID
  end

  class NameProduct < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

  class ArchiveProduct < Infra::Command
    attribute :product_id, Infra::Types::UUID
  end
end
