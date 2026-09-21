module Crm
  class RegisterCustomer
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :customer_id, :name
    alias aggregate_id customer_id

    def initialize(customer_id, name)
      @customer_id = customer_id
      @name = name
      valid = @customer_id.is_a?(String) && UUID.match?(@customer_id) && @name.is_a?(String)
      raise Infra::Command::Invalid unless valid
    end
  end
end
