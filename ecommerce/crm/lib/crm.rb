require "infra"
require_relative "crm/commands/promote_customer_to_vip"
require_relative "crm/commands/register_customer"
require_relative "crm/commands/assign_customer_to_order"
require_relative "crm/events/customer_promoted_to_vip"
require_relative "crm/events/customer_registered"
require_relative "crm/events/customer_assigned_to_order.rb"
require_relative "crm/customer_service"
require_relative "crm/customer"
require_relative "crm/order_service"
require_relative "crm/order"

module Crm
  class Configuration

    def call(cqrs)
      cqrs.register_command(RegisterCustomer, OnRegistration.new(cqrs.event_store))
      cqrs.register_command(PromoteCustomerToVip, OnPromoteCustomerToVip.new(cqrs.event_store))
      cqrs.register_command(AssignCustomerToOrder, OnSetCustomer.new(cqrs.event_store))
    end
  end
end
