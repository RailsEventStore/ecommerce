class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def execute(command)
    command.validate!
    handler = "CommandHandlers::#{command.class.name.demodulize}"
    handler.constantize.new.call(command)
  end
end
