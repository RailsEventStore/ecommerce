module Authentication
  class AccountConnectedToClient < Infra::Event
    attribute :account_id, Infra::Types::UUID
    attribute :client_id, Infra::Types::UUID
  end
end
