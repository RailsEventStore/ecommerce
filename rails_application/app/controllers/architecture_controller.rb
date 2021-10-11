class ArchitectureController < ApplicationController
  def index
    @cqrs = Infra::Cqrs
  end
end