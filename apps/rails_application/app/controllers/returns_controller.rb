class ReturnsController < ApplicationController
  before_action -> { verify_order_in_store(params[:order_id]) }

  def edit
    @return = Returns::Return.find_by_uid!(params[:id])
    @return_items = build_return_items_list(@order.order_lines, @return.return_items)
  end

  def create
    return_id = SecureRandom.uuid
    create_draft_return(return_id)

    redirect_to edit_order_return_path(return_id, order_id: params[:order_id])
  end

  def add_item
    add_item_to_return
    redirect_to edit_order_return_path(params[:id], order_id: params[:order_id])
  rescue Ordering::Return::ExceedsOrderQuantityError
    flash[:alert] = "You cannot add more of this product to the return than is in the original order."
    redirect_to edit_order_return_path(params[:id], order_id: params[:order_id])
  end

  def remove_item
    remove_item_from_return
    redirect_to edit_order_return_path(params[:id], order_id: params[:order_id])
  rescue Ordering::Return::ReturnHaveNotBeenRequestedForThisProductError
    flash[:alert] = "This product is not added to the return."
    redirect_to edit_order_return_path(params[:id], order_id: params[:order_id])
  end

  private

  def create_draft_return_cmd(return_id)
    Ordering::CreateDraftReturn.new(return_id: return_id, order_id: params[:order_id])
  end

  def create_draft_return(return_id)
    command_bus.(create_draft_return_cmd(return_id))
  end

  def add_item_to_return_cmd
    Ordering::AddItemToReturn.new(return_id: params[:id], order_id: params[:order_id], product_id: params[:product_id])
  end

  def add_item_to_return
    command_bus.(add_item_to_return_cmd)
  end

  def remove_item_from_return_cmd
    Ordering::RemoveItemFromReturn.new(return_id: params[:id], order_id: params[:order_id], product_id: params[:product_id])
  end

  def remove_item_from_return
    command_bus.(remove_item_from_return_cmd)
  end

  def build_return_items_list(order_lines, return_items)
    order_lines.map { |order_line| build_return_item(order_line, return_items) }
  end

  def build_return_item(order_line, return_items)
    return_item = return_items.find { |item| item.product_uid == order_line.product_id } || initialize_return_item(order_line)

    return_item.order_line = order_line
    return_item
  end

  def initialize_return_item(order_line)
    Returns::ReturnItem.new(product_uid: order_line.product_id, quantity: 0, price: order_line.price)
  end
end
