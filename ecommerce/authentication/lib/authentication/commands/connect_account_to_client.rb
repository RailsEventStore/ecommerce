module Authentication
  class ConnectAccountToClient < Infra::Command
    attribute :account_id, Infra::Types::UUID
    attribute :client_id, Infra::Types::UUID
    alias aggregate_id account_id
  end
end
