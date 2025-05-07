module Client
  class InboxController < BaseController

    def index
      render html: ClientInbox::Rendering::InboxList.build(view_context, cookies[:client_id]), layout: true
    end
  end
end
