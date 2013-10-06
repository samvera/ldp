require 'faraday'

module Ldp
  class Client
    
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

    def get url
      resp = http.get do |req|                          
        req.url url
        yield req if block_given?
      end

      if Response.resource? resp
        Response.wrap self, resp
      else
        resp
      end
    end

    def delete url
      http.delete do |req|
        req.url url
        yield req if block_given?
      end
    end

    def post url, body = nil
      http.post do |req|
        req.url url
        req.headers['Content-Type'] = 'text/turtle'
        req.body = body
        yield req if block_given?
      end
    end

    def put url, body
      http.put do |req|
        req.url url
        req.headers['Content-Type'] = 'text/turtle'
        req.body = body
        yield req if block_given?
      end
    end

  end
end
