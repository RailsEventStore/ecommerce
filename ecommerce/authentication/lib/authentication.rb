require "infra"
require_relative "authentication/commands/connect_account_to_client"
require_relative "authentication/commands/set_login"
require_relative "authentication/commands/set_password_hash"
require_relative "authentication/commands/register_account"
require_relative "authentication/events/account_connected_to_client"
require_relative "authentication/events/account_registered"
require_relative "authentication/events/login_set"
require_relative "authentication/events/password_hash_set"
require_relative "authentication/account_service"
require_relative "authentication/account"

module Authentication
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(RegisterAccount, RegisterAccountHandler.new(event_store))
      command_bus.register(SetLogin, SetLoginHandler.new(event_store))
      command_bus.register(SetPasswordHash, SetPasswordHashHandler.new(event_store))
      command_bus.register(
        ConnectAccountToClient,
        ConnectAccountToClientHandler.new(event_store)
      )
    end
  end
end
