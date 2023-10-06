module Ecommerce
  module Persistence
    module Relations
      class Orders < ROM::Relation[:sql]
        schema(:orders, infer: true) do
        end
      end
    end
  end
end
