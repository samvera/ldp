module Ldp
  class Container::Basic < Container
    def members
      return enum_for(:members) unless block_given?
      contains.each { |k, x| yield x }
    end

    def contains
      @contains ||= Hash[get.graph.query(predicate: Ldp.contains).map do |x| 
        [x.object, Ldp::Resource::RdfSource.new(client, x.object, contained_graph(x.object))]
      end]
    end
    
    private
    def contained_graph subject
      g = RDF::Graph.new
      get.graph.query(subject: subject) do |stmt|
        g << stmt
      end
      g
    end
  end
end
