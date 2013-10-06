module Ldp
  class Resource
    attr_reader :client, :subject

    def initialize client, subject, data = nil
      @client = client
      @subject = subject
      @get = data
    end

    def subject_uri
      @subject_uri ||= RDF::URI.new subject
    end

    def reload
      Ldp::Resource.new client, subject
    end

    def graph
      @graph ||= begin
        original_graph = get.graph

        inlinedResources = get.graph.query(:predicate => Ldp.inlinedResource).map { |x| x.object }

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

    def get
      @get ||= client.get subject
    end

    def delete
      client.delete subject do |req|
        if @get
          req.headers['If-Match'] = get.etag
        end
      end
    end

    def update new_graph = nil
      new_graph ||= graph
      client.put subject, new_graph.dump(:ttl) do |req|
        if @get
          req.headers['If-Match'] = get.etag
        end
      end
    end
  end
end