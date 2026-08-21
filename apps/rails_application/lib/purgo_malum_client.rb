require "net/http"

class PurgoMalumClient
  SERVICE_URL = "https://www.purgomalum.com/service/containsprofanity"

  def allowed?(name)
    Net::HTTP.get_response(profanity_check_uri(name)).body.eql?("false")
  end

  private

  def profanity_check_uri(name)
    uri = URI(SERVICE_URL)
    uri.query = URI.encode_www_form(text: name)
    uri
  end
end
