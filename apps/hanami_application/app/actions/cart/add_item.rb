# frozen_string_literal: true

module HanamiApplication
  module Actions
    module Cart
      class AddItem < HanamiApplication::Action
        include Deps["command_bus", "read_models.catalog"]

        params do
          required(:product_id).filled(:string)
        end

        def handle(request, response)
          product = catalog.find(request.params[:product_id])
          order_id = request.session[:order_id] || draft_offer
          command_bus.call(
            Pricing::AddPriceItem.new(order_id: order_id, product_id: product.id, price: product.price)
          )
          request.session[:order_id] = order_id
          response.flash[:notice] = "#{product.name} added to cart"
          response.redirect_to routes.path(:root)
        end

        private

        def draft_offer
          SecureRandom.uuid.tap do |order_id|
            command_bus.call(Pricing::DraftOffer.new(order_id: order_id))
          end
        end
      end
    end
  end
end
