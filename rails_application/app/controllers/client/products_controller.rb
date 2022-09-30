module Client
  class ProductsController < ApplicationController
    layout 'client_panel'

    def index
      render html: PublicOffer::ProductsList.build(view_context), layout: true
    end

  end
end