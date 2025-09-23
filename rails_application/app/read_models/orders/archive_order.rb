module Orders
  class ArchiveOrder
    def call(event)
      order = Order.find_by(uid: event.data[:order_id])
      order&.update!(archived: true)
    end
  end
end