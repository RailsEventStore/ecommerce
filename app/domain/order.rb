module Domain
  class Order
    include AggregateRoot

    AlreadyCreated        = Class.new(StandardError)
    MissingCustomer       = Class.new(StandardError)

    def initialize(id = SecureRandom.uuid)
      @id = id
      @state = :draft
    end

    def create(order_number, customer_id)
      raise AlreadyCreated unless state == :draft
      raise MissingCustomer unless customer_id
      apply Events::OrderCreated.create(@id, order_number, customer_id)
    end

    def expire
      apply Events::OrderExpired.create(@id)
    end

    def add_item(product_id)
      raise AlreadyCreated unless state == :draft
      apply Events::ItemAddedToBasket.create(@id, product_id)
    end

    def remove_item(product_id)
      raise AlreadyCreated unless state == :draft
      apply Events::ItemRemovedFromBasket.create(@id, product_id)
    end

    def apply_order_created(event)
      @customer_id = event.customer_id
      @number = event.order_number
      @state = :created
    end

    def apply_order_expired(event)
      @state = :expired
    end

    def apply_item_added_to_basket(event)
      product_id = event.product_id
      order_line = find_order_line(product_id)
      unless order_line
        order_line = create_order_line(product_id)
        order_lines << order_line
      end
      order_line.increase_quantity
    end

    def apply_item_removed_from_basket(event)
      product_id = event.product_id
      order_line = find_order_line(product_id)
      return unless order_line
      order_line.decrease_quantity
      remove_order_line(order_line) if order_line.empty?
    end

    private
    attr_accessor :id, :customer_id, :order_number, :state

    def order_lines
      @order_lines ||= []
    end

    def find_order_line(product_id)
      order_lines.select{|line| line.product_id == product_id}.first
    end

    def create_order_line(product_id)
      OrderLine.new(product_id)
    end

    def remove_order_line(order_line)
      order_lines.delete(order_line)
    end
  end
end
