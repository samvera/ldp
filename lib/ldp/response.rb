module Ldp
  module Response

    ##
    # Wrap the raw Faraday respone with our LDP extensions
    def self.wrap client, raw_resp
      raw_resp.send(:extend, Ldp::Response)
      raw_resp.ldp_client = client
      raw_resp
    end

    ##
    # Extract the Link: headers from the HTTP resource
    def self.links raw_resp
      h = Hash.new { |hash, key| hash[key] = [] }
      Array(raw_resp.headers["Link"]).map { |x| x.split(", ") }.flatten.inject(h) do |memo, header|
        v = header.scan(/(.*);\s?rel="([^"]+)"/)

        if v.length == 1
          memo[v.first.last] << v.first.first
        end

        memo
      end
    end

    ##
    # Is the response an LDP resource?
    def self.resource? raw_resp
      links(raw_resp).fetch("type", []).include? Ldp.resource.to_s
    end

    ##
    # Is the response an LDP resource?
    def resource?
      Ldp::Response.resource?(self)
    end

    ##
    # Is the response an LDP container
    def container?
      graph.has_statement? RDF::Statement.new(subject, RDF.type, Ldp.container)
    end

    ##
    # Get the subject for the response
    def subject
      @subject ||= if has_page?
        graph.first_object [page_subject, Ldp.page_of, nil]
      else
        page_subject
      end
    end

    ##
    # Get the URI to the response
    def page_subject
      @page_subject ||= RDF::URI.new env[:url]
    end

    ##
    # Set the LDP client for this resource
    def ldp_client= client
      @ldp_client = client
    end

    ##
    # Get the LDP client
    def ldp_client
      @ldp_client
    end

    ##
    # Get the graph for the resource (or a blank graph if there is no metadata for the resource)
    def graph
      @graph ||= begin
        graph = RDF::Graph.new

        if resource?
          RDF::Reader.for(:ttl).new(StringIO.new(body), :base_uri => page_subject) do |reader|
            reader.each_statement do |s|
              graph << s
            end
          end
        end

        graph
      end
    end

    ##
    # Extract the ETag for the resource
    def etag
      headers['ETag']
    end

    ##
    # Extract the last modified header for the resource
    def last_modified
      headers['Last-Modified']
    end

    ##
    # Statements about the page
    def page
      @page_graph ||= begin
        g = RDF::Graph.new  

        if resource?
          res = graph.query RDF::Statement.new(page_subject, nil, nil)

          res.each_statement do |s|
            g << s
          end
        end

        g
      end
    end

    ##
    # Is the response paginated?
    def has_page?
      graph.has_statement? RDF::Statement.new(page_subject, RDF.type, Ldp.page)
    end

    ##
    # Is there a next page?
    def has_next?
      next_page != nil
    end

    ##
    # Get the URI for the next page
    def next_page
      graph.first_object [page_subject, Ldp.nextPage, nil]
    end

    ##
    # Get the URI to the first page
    def first_page
      if links['first']
        RDF::URI.new links['first']
      elsif graph.has_statement? RDf::Statement.new(page_subject, Ldp.nextPage, nil)
        subject
      end
    end

    ##
    # Get a list of inlined resources
    def resources
      graph.query RDF::Statement.new(page_subject, Ldp.inlinedResource, nil)
    end

    ##
    # Get a list of member resources
    def members
      graph.query RDF::Statement.new(page_subject, membership_predicate, nil)
    end

    ##
    # Predicate to use to determine container membership
    def membership_predicate
      graph.first_object [page_subject, Ldp.membership_predicate, nil]
    end

    def sort

    end

    ##
    # Link: headers from the HTTP response
    def links
      Ldp::Response.links(self)
    end
  end
end