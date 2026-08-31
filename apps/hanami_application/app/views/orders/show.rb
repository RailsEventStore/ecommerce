# frozen_string_literal: true

module HanamiApplication
  module Views
    module Orders
      class Show < HanamiApplication::View
        include Deps["read_models.catalog", "read_models.orders"]

        expose :order do |order_id:|
          orders.find(order_id)
        end

        expose :lines do |order|
          order.lines.values.map { |line| with_product_name(line) }
        end

        private

        def with_product_name(line)
          { name: catalog.find(line.product_id).name, quantity: line.quantity, price: line.price, value: line.value }
        end
      end
    end
  end
end
