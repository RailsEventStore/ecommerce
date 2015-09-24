module Command
  module Execute
    def execute(command, **args)
      command.validate!
      args = dependencies if args.empty?
      handler_for(command).new(**args).call(command)
    end

    private
    def handler_for(command)
      {
        Command::CreateOrder          => CommandHandlers::CreateOrder,
        Command::SetOrderAsExpired    => CommandHandlers::SetOrderAsExpired,
        Command::AddItemToBasket      => CommandHandlers::AddItemToBasket,
        Command::RemoveItemFromBasket => CommandHandlers::RemoveItemFromBasket,
      }.fetch(command.class)
    end
  end
end

