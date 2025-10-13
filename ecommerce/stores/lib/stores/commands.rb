module Stores
  class RegisterStore < Infra::Command
    attribute :store_id, Infra::Types::UUID
  end
end
