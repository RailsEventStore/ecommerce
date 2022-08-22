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
    def call(cqrs)
      cqrs.register_command(RegisterAccount, RegisterAccountHandler.new(cqrs.event_store), AccountRegistered)
      cqrs.register_command(SetLogin, SetLoginHandler.new(cqrs.event_store), LoginSet)
      cqrs.register_command(SetPasswordHash, SetPasswordHashHandler.new(cqrs.event_store), PasswordHashSet)
      cqrs.register_command(
        ConnectAccountToClient,
        ConnectAccountToClientHandler.new(cqrs.event_store),
        AccountConnectedToClient
      )
    end
  end
end
