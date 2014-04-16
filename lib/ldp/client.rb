require 'faraday'

module Ldp
  class Client

    require 'ldp/client/methods'

    include Ldp::Client::Methods

    def initialize *http_client
      initialize_http_client *http_client
    end

    # Find or initialize a new LDP resource by URI
    def find_or_initialize subject
      data = get(subject)

      unless data.is_a? Response
        raise "#{subject} is not an LDP Resource"
      end

      if data.container?
        Container.new self, subject, data
      else  
        Resource.new self, subject, data
      end
    end

    def logger
      Ldp.logger
    end
  end
end
