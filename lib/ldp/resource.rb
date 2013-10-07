module Ldp
  class Resource
    attr_reader :client, :subject

    ##
    # Create a new LDP resource with a blank RDF graph
    def self.create client, subject
      self.new client, subject, RDF::Graph.new
    end

    def initialize client, subject, graph_or_response = nil
      @client = client
      @subject = subject

      @graph = graph_or_response if graph_or_response.is_a? RDF::Graph
      @get = graph_or_response if graph_or_response.is_a? Ldp::Response
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      @subject_uri ||= RDF::URI.new subject
    end

    ##
    # Reload the LDP resource
    def reload
      Ldp::Resource.new client, subject
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      get
    end

    ##
    # Have we retrieved the content already?
    def retrieved_content?
      @get
    end

    ##
    # Get the resource
    def get
      @get ||= client.get subject
    end

    ##
    # Delete the resource
    def delete
      client.delete subject do |req|
        req.headers['If-Match'] = get.etag if retrieved_content?
      end
    end

    ##
    # Create a new resource at the URI
    def create
      raise "" if new?
      resp = client.post '', graph.dump(:ttl) do |req|
        req.headers['Slug'] = subject
      end

      @subject = resp.headers['Location']
      @subject_uri = nil
    end

    ##
    # Update the stored graph
    def update new_graph = nil
      new_graph ||= graph
      client.put subject, new_graph.dump(:ttl) do |req|
        req.headers['If-Match'] = get.etag if retrieved_content?
      end
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

    def self.check_for_differences_and_reload_resource old_object
      new_object = old_object.reload

      bijection = new_object.graph.bijection_to(old_object.graph)
      diff = RDF::Graph.new

      old_object.graph.each do |statement|
        if statement.has_blank_nodes?
          subject = bijection.fetch(statement.subject, false) if statement.subject.node?
          object = bijection.fetch(statement.object, false) if statement.object.node?
          bijection_statement = RDF::Statement.new :subject => subject || statemnet.subject, :predicate => statement.predicate, :object => object || statement.object

          diff << statement if subject === false or object === false or new_object.graph.has_statement?(bijection_statement)
        elsif !new_object.graph.has_statement? statement
          diff << statement
        end
      end

      diff
    end

    ##
    # Reload this resource as an LDP container
    def as_container
      Ldp::Container.new client, subject, @graph || @get
    end
  end
end