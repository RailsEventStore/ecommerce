class RefundsController < ApplicationController
  def edit
    @refund = Refunds::Refund.find_by_uid!(params[:id])
    @order = Orders::Order.find_by_uid(@refund.order_uid)
    @order_lines = @order.order_lines
  end

  def create
    refund_id = SecureRandom.uuid
    create_draft_refund(refund_id)

    redirect_to edit_order_refund_path(refund_id, order_id: params[:order_id])
  end

  def add_item
    add_item_to_refund
  end

  def remove_item
    remove_item_from_refund
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
end
