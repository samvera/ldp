module Ldp
  class Resource::BinarySource < Ldp::Resource
    attr_accessor :content

    def initialize client, subject, content_or_response = nil, base_path = ''
      super

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
      described_by = Array(head.links["describedby"]).first

      client.find_or_initialize described_by if described_by
    end

    # Override inspect so that `content` is never shown. It is typically too big to be helpful
    def inspect
      string = "#<#{self.class.name}:#{self.object_id} "
      fields = [:subject].map{|field| "#{field}=\"#{self.send(field)}\""}
      string << fields.join(", ") << ">"
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.NonRDFSource
    end
  end
end
