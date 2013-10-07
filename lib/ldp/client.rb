require 'faraday'

module Ldp
  class Client

    require 'ldp/client/methods'

    include Ldp::Client::Methods
    
    attr_reader :http

    def initialize *http_client
      if http_client.length == 1 and http_client.first.is_a? Faraday::Connection
        @http = http_client.first
      else 
        @http = Faraday.new *http_client  
      end
    end

    def find_or_initialize subject
      data = get(subject)

      if !data.is_a? Response
        raise "#{subject} is not an LDP Resource"
      end

      if data.container?
        Container.new self, subject, data
      else  
        Resource.new self, subject, data
      end
    end

  end
end
