# frozen_string_literal: true

class FakeEmailClient
  def initialize
    @sent_emails = []
  end

  def send_email(order_id)
    @sent_emails << order_id
  end

  def sent_emails
    @sent_emails
  end
end
