
Hanami.app.register_provider :command_bus do
  prepare do
    require "arkency/command_bus"
  
    register "command_bus", Arkency::CommandBus.new
  end
end
