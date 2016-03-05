module Ldp
  class Container::Direct < Container::Basic
    def members
      return enum_for(:members) unless block_given?
      
      get.graph.query(subject: subject, predicate: member_relation).map do |x| 
        yield contains[x.object] || Ldp::Resource::RdfSource.new(client, x.object)
      end
    end
    
    def member_relation
      graph.first_object(predicate: RDF::Vocab::LDP.hasMemberRelation) || RDF::Vocab::LDP.member
    end

    protected

    def interaction_model
      RDF::Vocab::LDP.DirectContainer
    end
  end
end
