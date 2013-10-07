module Ldp
  class Container < Resource
    ##
    # Add a resource to the LDP container
    def add *args
      # slug, graph
      # graph
      # slug

      case
      when (args.length > 2 || args.length == 0)

      when (args.length == 2)
        slug, graph = args
      when (args.first.is_a? RDF::Graph)
        slug = nil
        graph = args.first
      else
        slug = args.first
        graph = RDF::Graph.new
      end

      resp = client.post subject, graph.dump(:ttl) do |req|
        req.headers['Slug'] = slug
      end

      subject = resp.headers['Location']
      return client.find_or_initialize subject
    end
  end
end