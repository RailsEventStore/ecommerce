module Domain
  class Order
    include AggregateRoot

    AlreadySubmitted      = Class.new(StandardError)
    OrderExpired          = Class.new(StandardError)
    MissingCustomer       = Class.new(StandardError)

    def initialize(id)
      @id = id
      @state = :draft
      @order_lines = []
    end

    def submit(order_number, customer_id)
      raise AlreadySubmitted if state == :submitted
      raise OrderExpired if state == :expired
      raise MissingCustomer unless customer_id
      apply Events::OrderSubmitted.new(data: {order_id: id, order_number: order_number, customer_id: customer_id})
    end

    def expire
      raise AlreadySubmitted unless state == :draft
      apply Events::OrderExpired.new(data: {order_id: id})
    end

    def add_item(product_id)
      raise AlreadySubmitted unless state == :draft
      apply Events::ItemAddedToBasket.new(data: {order_id: id, product_id: product_id})
    end

    def remove_item(product_id)
      raise AlreadySubmitted unless state == :draft
      apply Events::ItemRemovedFromBasket.new(data: {order_id: id, product_id: product_id})
    end

    attr_reader :id
    private
    attr_accessor :state, :customer_id, :number, :order_lines

    def apply_order_submitted(event)
      @customer_id = event.data[:customer_id]
      @number = event.data[:order_number]
      @state = :submitted
    end

    def apply_order_expired(event)
      @state = :expired
    end

    def apply_item_added_to_basket(event)
      product_id = event.data[:product_id]
      order_line = find_order_line(product_id)
      unless order_line
        order_line = create_order_line(product_id)
        @order_lines << order_line
      end
      order_line.increase_quantity
    end

    def apply_item_removed_from_basket(event)
      product_id = event.data[:product_id]
      order_line = find_order_line(product_id)
      return unless order_line
      order_line.decrease_quantity
      remove_order_line(order_line) if order_line.empty?
    end

    def find_order_line(product_id)
      @order_lines.select{|line| line.product_id == product_id}.first
    end

    def create_order_line(product_id)
      Domain::OrderLine.new(product_id)
    end

    def remove_order_line(order_line)
      @order_lines.delete(order_line)
    end
  end
end
