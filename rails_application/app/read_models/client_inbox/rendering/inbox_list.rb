require 'ostruct'

module ClientInbox
  module Rendering
    class InboxList < Arbre::Component
      include Rails.application.routes.url_helpers

      def self.build(view_context, client_id)
        new(Arbre::Context.new(nil, view_context)).build(inbox_messages(client_id))
      end

      def build(messages, attributes = {})
        super(attributes)

        div class: "max-w-6xl mx-auto py-6 sm:px-6 lg:px-8" do
          inbox_header
          messages_list(messages)
        end
      end

      private

      def self.inbox_messages(client_id)
        ClientInbox::Message.where(client_uid: client_id).order(created_at: :desc).to_a
      end

      def inbox_header
        h1 class: "text-3xl font-bold text-gray-900 mb-6" do
          "Your Inbox"
        end
      end

      def messages_list(messages)
        return no_messages_message if messages.empty?
        
        div class: "bg-white shadow rounded-lg overflow-hidden" do
          ul class: "divide-y divide-gray-200" do
            messages.each do |message|
              li class: "p-4 hover:bg-gray-50 transition duration-150" do
                message_item(message)
              end
            end
          end
        end
      end

      def message_item(message)
        if message.read?
          read_message_item(message)
        else
          unread_message_item(message)
        end
      end

      def unread_message_item(message)
        div class: "flex items-start justify-between" do
          div class: "flex-1" do
            form action: client_inbox_mark_as_read_path, method: :post, class: "block", data: { turbo: false } do
              input type: "hidden", name: "authenticity_token", value: form_authenticity_token
              input type: "hidden", name: "message_id", value: message.id
              h3 class: message_title_classes(message), onclick: "this.closest('form').submit();" do
                message.title
              end
            end

            timestamp(message.created_at)
          end

          unread_indicator
        end
      end

      def read_message_item(message)
        div class: "flex items-start justify-between" do
          div class: "flex-1" do
            input type: "hidden", name: "authenticity_token", value: form_authenticity_token
            input type: "hidden", name: "message_id", value: message.id
            h3 class: message_title_classes(message) do
              message.title
            end

            timestamp(message.created_at)
          end
        end
      end

      def timestamp(created_at)
        span class: "text-sm text-gray-500" do
          time_ago_in_words(created_at) + " ago"
        end
      end

      def message_title_classes(message)
        message.read ? "text-gray-700 text-lg" : "font-bold text-gray-900 text-lg cursor-pointer"
      end

      def unread_indicator
        div class: "ml-2 flex-shrink-0" do
          span class: "inline-block h-2 w-2 rounded-full bg-blue-600"
        end
      end

      def no_messages_message
        div class: "bg-white shadow rounded-lg p-6 text-center text-gray-500" do
          "You have no messages"
        end
      end
    end
  end
end

