module Ldp
  class Resource
    require 'ldp/resource/binary_source'
    require 'ldp/resource/rdf_source'

    attr_reader :client, :subject

    ##
    # Create a new LDP resource with a blank RDF graph
    def self.create client, subject
      self.new client, subject, RDF::Graph.new
    end

    def initialize client, subject, graph_or_response = nil
      @client = client
      @subject = subject
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      @subject_uri ||= RDF::URI.new subject
    end

    ##
    # Reload the LDP resource
    def reload
      self.class.new client, subject
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
      @get ||= client.get(subject)
    end

    ##
    # Delete the resource
    def delete
      client.delete subject do |req|
        req.headers['If-Match'] = get.etag if retrieved_content?
      end
    end

  end
end
