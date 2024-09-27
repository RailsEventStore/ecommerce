module ClientOrders
  module ProductHandlers
    class RegisterProduct
      def call(event)
        Product.find_or_create_by(uid: event.data.fetch(:product_id))
      end
    end

    class ChangeProductName
      def call(event)
        Product.find_or_create_by(uid: event.data.fetch(:product_id)).update(
          name: event.data.fetch(:name)
        )
      end
    end

    class ChangeProductPrice
      def call(event)
        Product.find_or_create_by(uid: event.data.fetch(:product_id)).update(price: event.data.fetch(:price))
      end
    end

    class UpdateProductAvailability
      def call(event)
        product = Product.find_by(uid: event.data.fetch(:product_id))
        available = event.data.fetch(:available)

        product.update(available: available.positive?)
      end
    end
  end
end
