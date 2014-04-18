module Ldp
  class Resource::BinarySource < Ldp::Resource
    attr_accessor :content

    def initialize client, subject, content_or_response = nil
      super client, subject
      
      case content_or_response
      when Faraday::Response
        @get = content_or_response if current? content_or_response
      else
        @content = content_or_response
      end
    end
    
    def content
      @content ||= get.body
    end

    ##
    # Update the stored graph
    def update new_graph = nil
      client.put subject, content do |req|
        req.headers['If-Match'] = get.etag if retrieved_content?
      end
    end
    
    def described_by
      client.find_or_initialize Array(Ldp::Response.links(self)["describedby"]).first
    end
  end
end
