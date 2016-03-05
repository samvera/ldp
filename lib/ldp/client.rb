##
# LDP client for presenting an ORM on top of an LDP resource
module Ldp
  class Client

    require 'ldp/client/methods'
    require 'ldp/client/prefer_headers'
    include Ldp::Client::Methods

    def initialize *http_client
      initialize_http_client *http_client
    end

    # Find or initialize a new LDP resource by URI
    def find_or_initialize(subject, options = {})
      data = get(subject, options = {})

      Ldp::Resource.for(self, subject, data)
    end

    def logger
      Ldp.logger
    end
  end
end
