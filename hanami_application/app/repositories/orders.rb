module Ecommerce
  module Repositories
    class Orders < ROM::Repository[:orders]
      include Deps[container: "persistence.rom"]

      commands :create

      def by_uuid(uuid)
        orders.where(uuid: uuid).one
      end
    end
  end
end
