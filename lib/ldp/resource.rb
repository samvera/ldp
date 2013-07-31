module Ldp
  class Resource
    attr_reader :client, :subject

    def initialize client, subject, data = nil
      @client = client
      @subject = subject
      @get = data
    end

    def graph
      @graph ||= begin
        original_graph = get.graph

        inlinedResources = get.graph.query(:predicate => Ldp.inlinedResource).map { |x| x.object }

        unless inlinedResource.empty?
          new_graph = RDF::Graph.new

          original_graph.each_statement do |s|
            unless inlinedResource.include? s.subject
              new_graph << s
            end
          end

          new_graph
        else
          original_graph
        end
      end
    end

    def get
      @get ||= client.get subject
    end

    def delete
      client.delete subject do |req|
        if @get
          req.headers['If-Match'] << get.headers['ETag']
        end
      end

      @get = nil
      @graph = nil
    end

    def update
      client.put subject, graph.dump(:ttl) do |req|
        if @get
          req.headers['If-Match'] << get.headers['ETag']
        end
      end
      @get = nil
      @graph = nil
    end
  end
end