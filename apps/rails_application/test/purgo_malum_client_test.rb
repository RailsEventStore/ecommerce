require "test_helper"

class PurgoMalumClientTest < ActiveSupport::TestCase
  cover "PurgoMalumClient*"

  Response = Struct.new(:body)

  def test_allows_name_when_service_finds_no_profanity
    requested_uri = nil

    with_get_response_stub(->(uri) { requested_uri = uri; Response.new("false") }) do
      assert PurgoMalumClient.new.allowed?("nice name")
    end

    assert_equal(
      "https://www.purgomalum.com/service/containsprofanity?text=nice+name",
      requested_uri.to_s
    )
  end

  def test_does_not_allow_name_when_service_finds_profanity
    with_get_response_stub(->(_uri) { Response.new("true") }) do
      refute PurgoMalumClient.new.allowed?("bad name")
    end
  end

  private

  def with_get_response_stub(stub)
    Net::HTTP.singleton_class.alias_method(:original_get_response, :get_response)
    Net::HTTP.define_singleton_method(:get_response) { |uri| stub.call(uri) }
    yield
  ensure
    Net::HTTP.singleton_class.alias_method(:get_response, :original_get_response)
    Net::HTTP.singleton_class.remove_method(:original_get_response)
  end
end
