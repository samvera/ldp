module Ldp
  class Resource::BinarySource < Ldp::Resource
    attr_accessor :content

    def initialize client, subject, content = nil
      super client, subject
      @content = content
    end

    ##
    # Create a new resource at the URI
    def create
      raise "" if new?
      resp = client.post '', content do |req|
        req.headers['Slug'] = subject
      end

      @subject = resp.headers['Location']
      @subject_uri = nil
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
