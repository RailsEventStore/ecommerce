module Command
  module Execute
    def execute(command, **args)
      command.validate!
      handler = "CommandHandlers::#{command.class.name.demodulize}"
      args = dependencies if args.empty?
      handler.constantize.new(**args).call(command)
    end
  end
end

