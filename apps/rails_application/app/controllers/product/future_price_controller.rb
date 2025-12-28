module Product
  class FuturePriceController < ApplicationController
    def add_future_price
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream:
            turbo_stream.append(
              "future_prices",
              partial: "/products/future_price",
              locals: {
                disabled: false,
                valid_since: nil,
                price: nil
              }
          )
        end
      end
    end
  end
end
