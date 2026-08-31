# frozen_string_literal: true

module HanamiApplication
  module Views
    module Cart
      class Show < HanamiApplication::View
        include Deps["read_models.catalog", "read_models.orders"]

        expose :products do
          catalog.all
        end

        private_expose :order do |order_id: nil|
          orders.find(order_id) if order_id
        end

        expose :lines do |order|
          order ? order.lines.values.map { |line| with_product_name(line) } : []
        end

        expose :total do |order|
          order ? order.total : 0
        end

        private

        def with_product_name(line)
          { name: catalog.find(line.product_id).name, quantity: line.quantity, price: line.price, value: line.value }
        end
      end
    end
  end
end
