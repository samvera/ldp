require "rdf/turtle"

module Ldp
  class Resource::RdfSource < Ldp::Resource
    def initialize(client, subject, graph_or_response = nil, base_path = "")
      super

      unless graph_or_response.nil?
        case graph_or_response
        when RDF::Enumerable
          @graph = graph_or_response
        when Ldp::Response
          @graph = response_as_graph(graph_or_response)
        else
          raise ArgumentError, "Third argument to #{self.class}.new should be a RDF::Enumerable or a Ldp::Response. You provided #{graph_or_response.class}"
        end
      end

      return unless !@graph.nil? && subject.nil? && !@graph.empty?
      @subject = @graph.first.subject
    end

    def create
      # Legacy support
      if client.repository.nil?
        return super do |req|
          req.headers["Content-Type"] = "text/turtle"
        end
      end

      super
    end

    def content
      graph.dump(:ttl) if persisted? && graph
    end

    ##
    # graph_class may be overridden so that a subclass of RDF::Graph
    # is returned (e.g. an ActiveTriples resource)
    # @return [Class] a class that is an descendant of RDF::Graph
    def graph_class
      RDF::Graph
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.Resource unless client.options[:omit_ldpr_interaction_model]
    end

    private

    ##
    # @note tries to avoid doing a large scale copy of the {RDF::Repository}
    #   data structure by using the existing {Ldp::Response#graph} if
    #   {#graph_class} is {RDF::Graph}. otherwise, it tries to instantiate a
    #   new graph projected over the same underlying {RDF::Graph#data}. finally,
    #   if {#graph_class}'s initailizer doesn't accept a `data:` parameter, it
    #   shovels {Ldp::Response#graph} into a new object of that class.
    #
    # @param [Faraday::Response] graph query response
    # @return [RDF::Graph]
    def response_as_graph(resp)
      built = graph_class.new
      built << resp.graph
      built
    end

    ##
    # @param [RDF::Graph] original_graph The graph returned by the LDP server
    # @return [RDF::Graph] A graph stripped of any inlined resources present in the original
    def filtered_graph(original_graph)
      contains_statements = original_graph.query([nil, RDF::Vocab::LDP.contains, nil])

      contains_statements.each_object do |contained_uri|
        original_graph.delete(original_graph.query([contained_uri, nil, nil]))
      end

      original_graph
    end
  end
end
