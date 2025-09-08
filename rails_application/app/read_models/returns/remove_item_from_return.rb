module Returns
  class RemoveItemFromReturn
    def call(event)
      return_record = Return.find_by!(uid: event.data.fetch(:return_id))
      item = return_record.return_items.find_by!(product_uid: event.data.fetch(:product_id))

      return_record.total_value -= item.price
      item.quantity -= 1

      ActiveRecord::Base.transaction do
        return_record.save!
        item.quantity > 0 ? item.save! : item.destroy!
      end
    end
  end

  # Backward compatibility alias  
  RemoveItemFromRefund = RemoveItemFromReturn
end