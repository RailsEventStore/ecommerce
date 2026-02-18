class ActivitiesController < ApplicationController
  def index
    @activities = Activities.all
  end
end
