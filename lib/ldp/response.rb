module Ldp
  module Response
    def self.wrap client, raw_resp
      raw_resp.send(:extend, Ldp::Response)
      raw_resp.ldp_client = client
      raw_resp
    end

    def self.links raw_resp
      h = Hash.new { |hash, key| hash[key] = [] }
      Array(raw_resp.headers["Link"]).inject(h) do |memo, header|
        v = header.scan(/(.*);\s?rel="([^"]+)"/)

        if v.length == 1
          memo[v.first.last] << v.first.first
        end

        memo
      end
    end

    def self.resource? raw_resp
      links(raw_resp).fetch("type").include? Ldp.resource
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

        RDF::Reader.for(:ttl).new(StringIO.new(body), :base_uri => page_subject) do |reader|
          reader.each_statement do |s|
            graph << s
          end
        end

        graph
      end
    end

    def etag
      headers['ETag']
    end

    def last_modified
      headers['Last-Modified']
    end

    def page
      @page_graph ||= begin
        g = RDF::Graph.new  

        res = graph.query RDF::Statement.new(page_subject, nil, nil)

        res.each_statement do |s|
          g << s
        end

        g
      end
    end

    def has_page?
      graph.has_statement? RDF::Statement.new(page_subject, RDF.type, Ldp.page)
    end

    def has_next?
      next_page != nil
    end

    def next_page
      graph.first_object [page_subject, Ldp.nextPage, nil]
    end

    def first_page
      if links['first']
        RDF::URI.new links['first']
      elsif graph.has_statement? RDf::Statement.new(page_subject, Ldp.nextPage, nil)
        subject
      end
    end

    def resources
      graph.query RDF::Statement.new(page_subject, Ldp.inlinedResource, nil)
    end

    def members
      graph.query RDF::Statement.new(page_subject, membership_predicate, nil)
    end

    def membership_predicate
      graph.first_object [page_subject, Ldp.membership_predicate, nil]
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
      @subject ||= if has_page?
        graph.first_object [page_subject, Ldp.page_of, nil]
      else
        page_subject
      end

    end

    def page_subject
      @page_subject ||= RDF::URI.new env[:url]
    end

    def links
      Ldp::Response.links(self)
    end
  end
end