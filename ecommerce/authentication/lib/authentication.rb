require "infra"
require_relative "authentication/commands/register_account"
require_relative "authentication/events/account_registered"
require_relative "authentication/account_service"
require_relative "authentication/account"

module Authentication
  class Configuration
    def call(cqrs)
      cqrs.register_command(RegisterAccount, OnRegistration.new(cqrs.event_store), AccountRegistered)
    end
  end
end
