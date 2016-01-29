class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  include Command::Execute
  include EventStoreSetup

  protected
  def dependencies
    {
      repository:       AggregateRoot::Repository.new(event_store),
      number_generator: Domain::Services::NumberGenerator.new
    }
  end
end
