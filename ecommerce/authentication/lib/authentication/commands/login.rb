module Authentication
  class Login < Infra::Command
    attribute :account_id, Infra::Types::UUID
    attribute :password, Infra::Types::String
  end
end
