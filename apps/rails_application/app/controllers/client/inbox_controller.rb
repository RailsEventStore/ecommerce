module Client
  class InboxController < BaseController

    def index
      render html: ClientInbox::Rendering::InboxList.build(view_context, current_client_id), layout: true
    end

    def mark_as_read
      ClientInbox.authorize(current_client_id, params[:message_id])
      command_bus.call(Communication::ReadMessage.new(message_id: params[:message_id]))
      redirect_to client_inbox_path
    rescue ClientInbox::NotAuthorized
      head :not_found
    end
  end
end
