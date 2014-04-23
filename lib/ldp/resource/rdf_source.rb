module Ldp
  class Resource::RdfSource < Ldp::Resource

    def initialize client, subject, graph_or_response = nil
      super client, subject, graph_or_response

      case graph_or_response
        when RDF::Graph
          @graph = graph_or_response
        when Ldp::Response
        when NilClass
          #nop
        else
          raise ArgumentError, "Third argument to #{self.class}.new should be a RDF::Graph or a Ldp::Response. You provided #{graph_or_response.class}"
      end
    end
    
    def create
      super do |req|
        req.headers = { "Content-Type" => "text/turtle" }
      end
    end
    
    def content
      graph.dump(:ttl) if graph
    end

    def graph
      @graph ||= RDF::Graph.new if new?
      @graph ||= begin
        original_graph = get.graph

        inlinedResources = get.graph.query(:predicate => Ldp.contains).map { |x| x.object }

        # we want to scope this graph to just statements about this model, not contained relations
        unless inlinedResources.empty?
          new_graph = RDF::Graph.new

          original_graph.each_statement do |s|
            unless inlinedResources.include? s.subject
              new_graph << s
            end
          end

          new_graph
        else
          original_graph
        end
      end
    end
  end
end
