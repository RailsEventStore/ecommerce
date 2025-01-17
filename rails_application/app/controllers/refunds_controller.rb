class RefundsController < ApplicationController
  def edit
    @refund = Refunds::Refund.find_by_uid!(params[:id])
    @order = Orders::Order.find_by_uid!(@refund.order_uid)
    @refund_items = build_refund_items_list(@order.order_lines, @refund.refund_items)
  end

  def create
    refund_id = SecureRandom.uuid
    create_draft_refund(refund_id)

    redirect_to edit_order_refund_path(refund_id, order_id: params[:order_id])
  end

  def add_item
    add_item_to_refund
    redirect_to edit_order_refund_path(params[:id], order_id: params[:order_id])
  rescue Ordering::Refund::ExceedsOrderQuantityError
    flash[:alert] = "You cannot add more of this product to the refund than is in the original order."
    redirect_to edit_order_refund_path(params[:id], order_id: params[:order_id])
  end

  def remove_item
    remove_item_from_refund
    redirect_to edit_order_refund_path(params[:id], order_id: params[:order_id])
  rescue Ordering::Refund::RefundHaveNotBeenRequestedForThisProductError
    flash[:alert] = "This product is not added to the refund."
    redirect_to edit_order_refund_path(params[:id], order_id: params[:order_id])
  end

  private

  def create_draft_refund_cmd(refund_id)
    Ordering::CreateDraftRefund.new(refund_id: refund_id, order_id: params[:order_id])
  end

  def create_draft_refund(refund_id)
    command_bus.(create_draft_refund_cmd(refund_id))
  end

  def add_item_to_refund_cmd
    Ordering::AddItemToRefund.new(refund_id: params[:id], order_id: params[:order_id], product_id: params[:product_id])
  end

  def add_item_to_refund
    command_bus.(add_item_to_refund_cmd)
  end

  def remove_item_from_refund_cmd
    Ordering::RemoveItemFromRefund.new(refund_id: params[:id], order_id: params[:order_id], product_id: params[:product_id])
  end

  def remove_item_from_refund
    command_bus.(remove_item_from_refund_cmd)
  end

  def build_refund_items_list(order_lines, refund_items)
    order_lines.map { |order_line| build_refund_item(order_line, refund_items) }
  end

  def build_refund_item(order_line, refund_items)
    refund_item = refund_items.find { |item| item.product_uid == order_line.product_id } || initialize_refund_item(order_line)

    refund_item.order_line = order_line
    refund_item
  end

  def initialize_refund_item(order_line)
    Refunds::RefundItem.new(product_uid: order_line.product_id, quantity: 0, price: order_line.price)
  end
end
