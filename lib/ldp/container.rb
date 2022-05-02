module Ldp
  class Container < Resource::RdfSource
    require "ldp/container/basic"
    require "ldp/container/direct"
    require "ldp/container/indirect"

    def self.for(client, subject, data)
      case
      when data.types.include?(RDF::Vocab::LDP.IndirectContainer)
        Ldp::Container::Indirect.new client, subject, data
      when data.types.include?(RDF::Vocab::LDP.DirectContainer)
        Ldp::Container::Direct.new client, subject, data
      else
        Ldp::Container::Basic.new client, subject, data
      end
    end

    class << self
      alias new_from_response for
    end

    def contained_statements
      graph.query([nil, RDF::Vocab::LDP.contains, nil])
    end

    def contains
      @contains ||= Hash[contained_statements.map do |x|
        child_graph = build_child_graph(x.object)
        [x.object, Ldp::Resource::RdfSource.new(client, x.object, child_graph)]
      end]
    end

    ##
    # Add a new resource to the LDP container
    def add(*args)
      case
      when (args.length > 2 || args.length == 0)
        raise(ArgumentError, "LDP::Container#add invoked with invalid arguments: \n" + args.join("\n") + ")")
      when (args.length == 2)
        slug, subgraph = args
      when (args.first.is_a? RDF::Enumerable)
        slug = nil
        subgraph = args.first
      else
        subgraph = [args.first]
      end

      if client.repository
        subgraph.each do |statement|
          persisted.add(statement)
        end
      else
        # Legacy
        post_body = (graph_or_content.is_a?(RDF::Enumerable) ? graph_or_content.dump(:ttl) : graph_or_content)

        response = client.post subject, post_body do |request|
          request.headers["Slug"] = slug
          request.headers["Content-Type"] = "text/turtle"
        end

        client.find_or_initialize(response.headers["Location"])
      end
    end

    private

    def build_child_graph(child)
      child_graph = RDF::Graph.new

      graph.query([child, nil, nil]) do |s|
        child_graph << s
      end

      child_graph
    end

    def rdf_source_for(object)
      child_graph = build_child_graph(object)
      source_graph = child_graph unless child_graph.empty?

      Ldp::Resource::RdfSource.new(client, object, source_graph)
    end
  end
end
