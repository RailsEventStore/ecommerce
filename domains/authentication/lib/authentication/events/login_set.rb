module Authentication
  class LoginSet < Infra::Event
    attribute :account_id, Infra::Types::UUID
    attribute :login, Infra::Types::String
  end
end
