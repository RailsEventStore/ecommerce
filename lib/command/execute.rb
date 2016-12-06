module Command
  module Execute
    def execute(command)
      command.validate!
      handler_for(command).call(command)
    end

    private
    def handler_for(command)
      {
        Command::CreateOrder          => CommandHandlers::CreateOrder.new(
          number_generator: dependencies.fetch(:number_generator)
        ),
        Command::SetOrderAsExpired    => CommandHandlers::SetOrderAsExpired.new,
        Command::AddItemToBasket      => CommandHandlers::AddItemToBasket.new,
        Command::RemoveItemFromBasket => CommandHandlers::RemoveItemFromBasket.new,
      }.fetch(command.class)
    end
  end
end

