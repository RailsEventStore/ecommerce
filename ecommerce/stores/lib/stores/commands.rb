module Stores
  class RegisterStore < Infra::Command
    attribute :store_id, Infra::Types::UUID
  end

  class NameStore < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :name, Infra::Types.Instance(StoreName)
  end
end
