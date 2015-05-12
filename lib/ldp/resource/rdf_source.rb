require 'rdf/turtle'
require 'rdf/rdfxml'
module Ldp
  class Resource::RdfSource < Ldp::Resource

    def initialize client, subject, graph_or_response = nil, base_path = ''
      super

      case graph_or_response
        when RDF::Enumerable
          @graph = graph_or_response
        when Ldp::Response
        when NilClass
          #nop
        else
          raise ArgumentError, "Third argument to #{self.class}.new should be a RDF::Enumerable or a Ldp::Response. You provided #{graph_or_response.class}"
      end
    end

    def create
      super do |req|
        req.headers["Content-Type"] = "text/turtle"
      end
    end

    def content
      graph.dump(:ttl) if graph
    end

    def graph
      @graph ||= new? ? build_empty_graph : build_graph(response_as_graph(get))
    end

    def build_empty_graph
      graph_class.new
    end

    ##
    # graph_class may be overridden so that a subclass of RDF::Graph
    # is returned (e.g. an ActiveTriples resource)
    # @returns [Class] a class that is an descendant of RDF::Graph
    def graph_class
      RDF::Graph
    end



    private
      ##
      # @param [Faraday::Response] graph query response
      # @return [RDF::Graph]
      def response_as_graph(resp)
        content_type = resp.headers['Content-Type'] || 'text/turtle'
        content_type = Array(content_type).first
        format = Array(RDF::Format.content_types[content_type]).first
        source = resp.body
        reader = RDF::Reader.for(content_type:content_type).new(source, base_uri:subject)
        graph = build_empty_graph
        reader.each_statement do |stmt|
          graph << stmt
        end
        graph
      end
      ##
      # @param [RDF::Graph] original_graph The graph returned by the LDP server
      # @return [RDF::Graph] A graph striped of any inlined resources present in the original
      def build_graph(original_graph)
        inlined_resources = response_as_graph(get).query(predicate: Ldp.contains).map { |x| x.object }

        # we want to scope this graph to just statements about this model, not contained relations
        if inlined_resources.empty?
          original_graph
        else
          graph_without_inlined_resources(original_graph, inlined_resources)
        end
      end

      def graph_without_inlined_resources(original_graph, inlined_resources)
        new_graph = build_empty_graph

        original_graph.each_statement do |s|
          unless inlined_resources.include? s.subject
            new_graph << s
          end
        end

        new_graph
      end
  end
end
