module Ldp
  class Container < Resource
    def add graph
      client.post subject, graph.dump(:ttl)
    end
  end
end