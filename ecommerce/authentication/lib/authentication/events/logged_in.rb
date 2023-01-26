module Authentication
  class LoggedIn < Infra::Event
    attribute :account_id, Infra::Types::UUID
  end
end
