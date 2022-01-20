module Crm
  class CustomerPromotedToVip < Infra::Event
    attribute :customer_id, Infra::Types::UUID
  end
end
