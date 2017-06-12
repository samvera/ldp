require 'rdf/turtle'
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
      @graph ||= begin
                   if subject.nil?
                     build_empty_graph
                   else
                     filtered_graph(response_graph)
                   end
                 rescue Ldp::NotFound
                   # This is an optimization that lets us avoid doing HEAD + GET
                   # when the object exists. We just need to handle the 404 case
                   build_empty_graph
                 end
    end

    def build_empty_graph
      graph_class.new
    end

    ##
    # graph_class may be overridden so that a subclass of RDF::Graph
    # is returned (e.g. an ActiveTriples resource)
    # @return [Class] a class that is an descendant of RDF::Graph
    def graph_class
      RDF::Graph
    end

    ##
    # Parse the graph returned by the LDP server into an RDF::Graph
    # @return [RDF::Graph]
    def response_graph
      @response_graph ||= response_as_graph(get)
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.Resource unless client.options[:omit_ldpr_interaction_model]
    end

    private
      ##
      # @param [Faraday::Response] graph query response
      # @return [RDF::Graph]
      def response_as_graph(resp)
        graph = build_empty_graph
        resp.each_statement do |stmt|
          graph << stmt
        end
        graph
      end

      ##
      # @param [RDF::Graph] original_graph The graph returned by the LDP server
      # @return [RDF::Graph] A graph stripped of any inlined resources present in the original
      def filtered_graph(original_graph)
        inlined_resources = original_graph.query(predicate: RDF::Vocab::LDP.contains).map { |x| x.object }

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
