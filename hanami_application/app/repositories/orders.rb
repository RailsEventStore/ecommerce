module Ecommerce
  module Repositories
    class Orders < ROM::Repository[:orders]
      include Deps[container: "persistence.rom"]

      commands :create

      def by_id(id)
        orders.by_pk(id).one
      end
    end
  end
end
