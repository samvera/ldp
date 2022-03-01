module Ldp
  class Container::Indirect < Container::Direct
    def members
      return enum_for(:members) unless block_given?

      response_graph.query([nil, member_relation, subject]).map do |x|
        yield rdf_source_for(x.object)
      end
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.IndirectContainer
    end
  end
end
