module Returns
  class AddItemToReturn
    def call(event)
      return_record = Return.find_by!(uid: event.data.fetch(:return_id))
      product = Orders::Product.find_by!(uid: event.data.fetch(:product_id))

      item = return_record.return_items.find_or_create_by(product_uid: product.uid) do |item|
        item.price = product.price
        item.quantity = 0
      end

      return_record.total_value += item.price
      item.quantity += 1

      ActiveRecord::Base.transaction do
        return_record.save!
        item.save!
      end
    end
  end

  # Backward compatibility alias
  AddItemToRefund = AddItemToReturn
end
