module Authentication
  class RegisterAccount < Infra::Command
    attribute :account_id, Infra::Types::UUID
    alias aggregate_id account_id
  end
end
