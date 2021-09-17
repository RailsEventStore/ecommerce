module ProductCatalog
  class Product
    AlreadyRegistered = Class.new(StandardError)

    attr_reader :id, :name, :price, :stock_level

    def initialize(**attributes)
      @id, @name, @registered_at, @price, @stock_level =
        attributes.values_at(:id, :name, :registered_at, :price, :stock_level)
    end

    def register(name)
      raise AlreadyRegistered if @registered_at
      @name = name
      @registered_at = Time.now
    end

    def set_price(price)
      @price = price
    end

    def set_stock_level(value)
      @stock_level = value
    end

    def to_h
      { name: name, id: id, price: price, stock_level: stock_level, registered_at: @registered_at }
    end
  end
end
