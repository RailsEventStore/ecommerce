class EventsCatalogController < ApplicationController
  def index
    Rails.root.join('../events_catalog/out/')
    render file: '../events_catalog/out/index.html'
  end
end
