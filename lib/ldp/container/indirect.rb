module Ldp
  class Container::Indirect < Container::Direct
    def members
      return enum_for(:members) unless block_given?

      response_graph.query(predicate: member_relation, object: subject).map do |x|
        yield contains[x.object] || Ldp::Resource::RdfSource.new(client, x.object)
      end
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.IndirectContainer
    end
  end
end
