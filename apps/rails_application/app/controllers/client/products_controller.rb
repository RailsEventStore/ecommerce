module Client
  class ProductsController < BaseController

    def index
      render html: PublicOffer::ProductsList.build(view_context, current_store_id), layout: true
    end

  end
end