require 'rdf/ldp'

module Ldp
  class Resource
    require 'ldp/resource/binary_source'
    require 'ldp/resource/rdf_source'

    attr_reader :client, :subject
    attr_accessor :content

    def self.for(client, subject, response)
      if client.repository.nil?

        # Legacy support
        found = case
                when response.container?
                  Ldp::Container.for client, subject, response
                when response.rdf_source?
                  Resource::RdfSource.new client, subject, response
                else
                  Resource::BinarySource.new client, subject, response
                end

        return found
      end

      subject_uri = if subject.is_a?(URI::HTTP)
                      RDF::URI(subject.to_s)
                    else
                      RDF::URI(response.response.env.url)
                    end

      RDF::LDP::Resource.find(subject_uri, client.repository)
    end

    def initialize client, subject, get_response = nil, base_path = ''
      @client = client
      @subject = subject
      @get_response = get_response if get_response.is_a?(Faraday::Response) && current?(get_response)
      @base_path = base_path
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      @subject_uri ||= RDF::URI(subject)
    end

    ##
    # Reload the LDP resource
    def reload
      self.class.new client, subject, @get_response
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      binding.pry
      return persisted.nil? if client.repository


      # Legacy support
      subject.nil? || head == None
    end

    def persisted
      @persisted ||= begin
                       binding.pry
                       RDF::LDP::Resource.find(subject, client.repository)
                     rescue RDF::LDP::NotFound
                       nil
                     end
    end

    ##
    # Have we retrieved the content already?
    def retrieved_content?
      @get_response
    end

    ##
    # Get the resource
    def get
      return @get_response ||= persisted if client.repository

      # Legacy support
      @get_response ||= client.get(subject)
    end

    def head
      @head ||= begin
        @get_response || client.head(subject)
                rescue Ldp::NotFound
                  None
      end
    end

    ##
    # Delete the resource
    def delete
      client.delete subject do |req|
        req.headers['If-Unmodified-Since'] = get.last_modified if retrieved_content?
      end
    end

    def save
      new? ? create : update
    end

    def self.rdf_ldp_class
      RDF::LDP::Resource
    end

    ##
    # Create a new resource at the URI
    # @return [RdfSource] the new representation
    # @raise [Ldp::Conflict] if you attempt to call create on an existing resource
    def create &block
      raise Ldp::Conflict, "Can't call create on an existing resource (#{subject})" unless new?

      binding.pry
      if client.repository
        built = self.class.rdf_ldp_class.new(subject_uri)
        @persisted = built.create(content, 'application/n-triples')

        @subject_uri = @persisted.subject_uri
        @subject = @subject_uri.to_s
      else
        # Legacy support
        verb = subject.nil? ? :post : :put
        resp = client.send(verb, (subject || @base_path), content) do |req|
          req.headers["Link"] = "<#{interaction_model}>;rel=\"type\"" if interaction_model
          yield req if block_given?
        end

        @subject = resp.headers['Location']
        @subject_uri = nil
        reload
      end
    end

    ##
    # Update the stored graph
    def update new_content = nil
      new_content ||= content
      resp = client.put subject, new_content do |req|
        req.headers['If-Unmodified-Since'] = get.last_modified if retrieved_content?
        yield req if block_given?
      end
      update_cached_get(resp) if retrieved_content?
      resp
    end

    def head_request
      client.head(subject)
    end

    def current?(cached_response = nil)
      cached_response ||= @get_response
      return true if new? and subject.nil?

      #new_response = client.head(subject)
      new_response = head_request

      #return false unless response.headers['ETag']
      #return false unless response.headers['Last-Modified']

      return false unless new_response.headers['ETag'] == cached_response.headers['ETag']
      return false unless new_response.headers['Last-Modified'] == cached_response.headers['Last-Modified']

      true
    end

    # Updates the `E-tag` and `last-modified` header values for the resource
    def update_cached_get(cached_response)
      cached_response = Response.new(cached_response)

      if cached_response.etag.nil? || cached_response.last_modified.nil?
        cached_response = head_request
      end

      @get_response.etag = cached_response.etag
      @get_response.last_modified = cached_response.last_modified
    end

    protected

    def interaction_model
      nil
    end
  end
end
