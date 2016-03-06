module Ldp
  class Response
    extend Forwardable
    def_delegators :@response, :body, :headers, :env, :success?, :status

    require 'ldp/response/paging'
    include Ldp::Response::Paging

    TYPE = 'type'.freeze

    attr_reader :response

    def initialize(response)
      @response = response
    end

    ##
    # Extract the Link: headers from the HTTP resource
    def links
      @links ||= begin
        h = {}
        Array(headers['Link'.freeze]).map { |x| x.split(','.freeze) }.flatten.inject(h) do |memo, header|
          m = header.match(/<(?<link>.*)>;\s?rel="(?<rel>[^"]+)"/)
          if m
            memo[m[:rel]] ||= []
            memo[m[:rel]] << m[:link]
          end

          memo
        end
      end
    end

    def applied_preferences
      h = {}

      Array(headers['Preference-Applied'.freeze]).map { |x| x.split(",") }.flatten.inject(h) do |memo, header|
        m = header.match(/(?<key>[^=;]*)(=(?<value>[^;,]*))?(;\s*(?<params>[^,]*))?/)
        includes = (m[:params].match(/include="(?<include>[^"]+)"/)[:include] || "").split(" ")
        omits = (m[:params].match(/omit="(?<omit>[^"]+)"/)[:omit] || "").split(" ")
        memo[m[:key]] = { value: m[:value], includes: includes, omits: omits }
      end
    end

    ##
    # Is the response an LDP resource?

    def resource?
      Array(links[TYPE]).include? RDF::Vocab::LDP.Resource.to_s
    end

    ##
    # Is the response an LDP container?
    def container?
      [
        RDF::Vocab::LDP.BasicContainer,
        RDF::Vocab::LDP.DirectContainer,
        RDF::Vocab::LDP.IndirectContainer
      ].any? { |x| Array(links[TYPE]).include? x.to_s }
    end

    ##
    # Is the response an LDP RDFSource?
    #   ldp:Container is a subclass of ldp:RDFSource
    def rdf_source?
      container? || Array(links[TYPE]).include?(RDF::Vocab::LDP.RDFSource)
    end

    def dup
      super.tap do |new_resp|
        unless new_resp.instance_variable_get(:@graph).nil?
          new_resp.remove_instance_variable(:@graph)
        end
      end
    end

    ##
    # Get the subject for the response
    def subject
      page_subject
    end

    ##
    # Get the URI to the response
    def page_subject
      @page_subject ||= RDF::URI.new env[:url]
    end

    ##
    # Is the response paginated?
    def has_page?
      rdf_source? && graph.has_statement?(RDF::Statement.new(page_subject, RDF.type, RDF::Vocab::LDP.Page))
    end

    ##
    # Get the graph for the resource (or a blank graph if there is no metadata for the resource)
    def graph
      @graph ||= begin
        raise Ldp::UnexpectedContentType, "The resource at #{page_subject} is not an RDFSource" unless rdf_source?
        graph = RDF::Graph.new

        if resource?
          RDF::Reader.for(:ttl).new(response_body, base_uri: page_subject) do |reader|
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
      @etag ||= headers['ETag'.freeze]
    end

    def etag=(val)
      @etag = val
    end

    ##
    # Extract the last modified header for the resource
    def last_modified
      @last_modified ||= headers['Last-Modified'.freeze]
    end

    def last_modified=(val)
      @last_modified = val
    end

    ##
    # Extract the Link: rel="type" headers for the resource
    def types
      Array(links[TYPE])
    end

    RETURN = 'return'.freeze

    def includes? preference
      key = Ldp.send("prefer_#{preference}") if Ldp.respond_to("prefer_#{preference}")
      key ||= preference
      preferences[RETURN][:includes].include?(key) || !preferences["return"][:omits].include?(key)
    end

    def minimal?
      preferences[RETURN][:value] == "minimal"
    end

    private

      # Get the body and ensure it's UTF-8 encoded. Since Fedora 9.3 isn't
      # returning a charset, then Net::HTTP is just returning ASCII-8BIT
      # See https://github.com/ruby-rdf/rdf-turtle/issues/13
      # See https://jira.duraspace.org/browse/FCREPO-1750
      def response_body
        body.force_encoding('utf-8')
      end
  end
end
