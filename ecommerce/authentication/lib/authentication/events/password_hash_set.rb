module Authentication
  class PasswordHashSet < Infra::Event
    attribute :account_id, Infra::Types::UUID
    attribute :password_hash, Infra::Types::String
  end
end
