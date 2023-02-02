class EventsCatalogController < ApplicationController
  def index
    render file: Rails.root.join("events_catalog/out/index.html")
  end
end
