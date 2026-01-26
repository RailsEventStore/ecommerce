module Authentication
  class AccountRegistered < Infra::Event
    attribute :account_id, Infra::Types::UUID
  end
end
