require "infra"
require_relative "crm/commands/promote_customer_to_vip"
require_relative "crm/commands/register_customer"
require_relative "crm/events/customer_promoted_to_vip"
require_relative "crm/events/customer_registered"

require_relative "crm/service"
require_relative "crm/customer"

module Crm
  class Configuration

    def call(cqrs)
      cqrs.register_command(RegisterCustomer, OnRegistration.new(cqrs.event_store), CustomerRegistered)
      cqrs.register_command(PromoteCustomerToVip, OnPromoteCustomerToVip.new(cqrs.event_store), CustomerPromotedToVip)
    end
  end
end
