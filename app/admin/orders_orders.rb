ActiveAdmin.register Orders::Order, as: 'Order' do
  controller { actions :show, :index, :cancel }

  member_action :cancel, method: %i[post] do
    command_bus.(
      Ordering::CancelOrder.new(order_id: Orders::Order.find(params[:id]).uid)
    )
    redirect_to admin_orders_path, notice: 'Order cancelled!'
  end

  action_item :cancel,
              only: %i[show],
              if: proc { 'Submitted' == resource.state } do
    link_to 'Cancel order',
            cancel_admin_order_path,
            method: :post,
            class: 'button',
            data: {
              confirm: 'Do you really want to hurt me?'
            }
  end
end
