module Ldp
  class Resource::BinarySource < Ldp::Resource
    attr_accessor :content

    def initialize client, subject, content_or_response = nil
      super client, subject, content_or_response
      
      case content_or_response
      when Faraday::Response
      else
        @content = content_or_response
      end
    end
    
    def content
      @content ||= get.body
    end
    
    def described_by
      client.find_or_initialize Array(Ldp::Response.links(self)["describedby"]).first
    end
  end
end
