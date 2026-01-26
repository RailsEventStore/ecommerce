module Authentication
  class SetPasswordHash < Infra::Command
    attribute :account_id, Infra::Types::UUID
    attribute :password_hash, Infra::Types::String
    alias aggregate_id account_id
  end
end
