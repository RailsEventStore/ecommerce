class ArchitectureController < ApplicationController
  def index
    @cqrs = Rails.configuration.cqrs
  end
end