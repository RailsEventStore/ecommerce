module ProductCatalog
  class RegisterProduct
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id

    def initialize(product_id)
      @product_id = product_id
      valid = UUID.match?(@product_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class NameProduct
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :name

    def initialize(product_id, name)
      @product_id = product_id
      @name = name
      valid = UUID.match?(@product_id) && @name.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class RequestProductNameChange
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :name

    def initialize(product_id, name)
      @product_id = product_id
      @name = name
      valid = UUID.match?(@product_id) && @name.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end

  class ModerateProductName
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :product_id, :name

    def initialize(product_id, name)
      @product_id = product_id
      @name = name
      valid = UUID.match?(@product_id) && @name.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
