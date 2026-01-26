module Authentication
  class SetLogin < Infra::Command
    attribute :account_id, Infra::Types::UUID
    attribute :login, Infra::Types::String
    alias aggregate_id account_id
  end
end
