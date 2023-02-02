class EventsCatalogController < ApplicationController
  def index
    render file: ENV["EVENTS_CATALOG_PATH"] || "../events_catalog/out/index.html"
  end
end
