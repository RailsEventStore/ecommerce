module Client
  class ProductsController < BaseController

    def index
      render html: PublicOffer::ProductsList.build(view_context), layout: true
    end

  end
end