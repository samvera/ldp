module Ldp
  module Response
    def self.wrap client, raw_resp
      raw_resp.send(:extend, Ldp::Response)
      raw_resp.ldp_client = client
      raw_resp
    end

    def self.links raw_resp
      Array(raw_resp.headers["Link"]).inject({}) do |memo, header|
        v = header.scan(/(.*);\s?rel="([^"]+)"/)

        if v.length == 1
          memo[v.first.last] ||= []
          memo[v.first.last] << v.first.first
        end

        memo
      end
    end

    def self.resource? raw_resp
      links(raw_resp).fetch("type", []).include? Ldp.resource
    end

    def ldp_client= client
      @ldp_client = client
    end

    def ldp_client
      @ldp_client
    end

    def graph
      @graph ||= begin
        graph = RDF::Graph.new

        RDF::Reader.for(:ttl).new(StringIO.new(body), :base_uri => subject) do |reader|
          reader.each_statement do |s|
            graph << s
          end
        end

        graph
      end
    end

    def etag

    end

    def last_modified

    end

    def page

    end

    def paginated?

    end

    def next_page

    end

    def first_page

    end

    def resources

    end

    def members

    end

    def resource?
      Ldp::Response.resource?(self)
    end

    def container?
      graph.has_statement? RDF::Statement.new(subject, RDF.type, Ldp.container)
    end

    def sort

    end

    def subject
      RDF::URI.new env[:url]
    end
  end
end