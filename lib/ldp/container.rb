module Ldp
  class Container < Resource::RdfSource
    require 'ldp/container/basic'
    require 'ldp/container/direct'
    require 'ldp/container/indirect'

    def self.new_from_response client, subject, data
      case
      when data.types.include?(Ldp.indirect_container)
        Ldp::Container::Indirect.new client, subject, data
      when data.types.include?(Ldp.direct_container)
        Ldp::Container::Direct.new client, subject, data
      else
        Ldp::Container::Basic.new client, subject, data
      end
    end

    ##
    # Add a new resource to the LDP container
    def add *args
      # slug, graph
      # graph
      # slug

      case
      when (args.length > 2 || args.length == 0)

      when (args.length == 2)
        slug, graph_or_content = args
      when (args.first.is_a? RDF::Enumerable)
        slug = nil
        graph_or_content = args.first
      else
        slug = args.first
        graph_or_content = RDF::Graph.new
      end

      resp = client.post subject, (graph_or_content.is_a?(RDF::Enumerable) ? graph_or_content.dump(:ttl) : graph_or_content) do |req|
        req.headers['Slug'] = slug
      end

      client.find_or_initialize resp.headers['Location']
    end
  end
end
