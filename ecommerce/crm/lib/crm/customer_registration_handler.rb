module Crm
  class CustomerRegistrationHandler
    def call(cmd)
      customer = Customer.find_or_initialize_by(id: cmd.customer_id)
      customer.register(cmd.name)
      customer.save!
    end
  end
end