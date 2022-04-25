require 'rdf/ldp'

module Ldp
  class Resource
    require 'ldp/resource/binary_source'
    require 'ldp/resource/rdf_source'

    attr_reader :client
    attr_accessor :content

    def self.for(client, subject, response)
      repository = if client.repository.nil?
                     RDF::Repository.new
                   else
                     client.repository
                   end

      subject_uri = if subject.is_a?(URI::HTTP)
                      RDF::URI(subject.to_s)
                    else
                      RDF::URI(response.response.env.url)
                    end

      RDF::LDP::Resource.find(subject_uri, repository)
    end

    def initialize(client, subject, http_response = nil, base_path = '')
      @client = client
      @subject = subject
      @http_response = http_response if http_response.is_a?(Faraday::Response) && current?(http_response)
      @base_path = base_path
    end

    ##
    # Get the graph subject as a URI
    # Legacy
    attr_reader :subject

    def self.build_subject_uri(value:, client:)
      return if value.nil?
      return if client.nil? || client.http.nil? || client.http.url_prefix.nil?
      prefix = client.http.url_prefix

      parsed = if !value.to_s.include?(prefix.to_s)
                 "#{prefix.to_s.chomp('/')}#{value}"
               else
                 value
               end

      RDF::URI.parse(parsed)
    end

    def subject_uri
      @subject_uri ||= begin
                         value = self.class.build_subject_uri(value: @subject, client: client)
                         RDF::URI.parse(value)
                       end
    end

    def uri
      subject
    end

    def to_uri
      uri
    end

    ##
    # Reload the LDP resource
    def reload
      self.class.new(client, subject)
    end

    def head_request
      client.head(subject)
    rescue Ldp::NotFound
      nil
    rescue Ldp::Gone
      nil
    end

    # Legacy
    def head
      head_request
    end

    def persisted?
      !@persisted.nil? || (!head_request.nil? && head_request.success?)
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      !persisted?
    end

    def repository
      client.repository || RDF::Repository.new
    end

    def find
      @persisted = RDF::LDP::Resource.find(subject, repository)
    end

    def persisted
      @persisted ||= begin
                       find
                     rescue RDF::LDP::NotFound
                       nil
                     end
    end

    def graph
      return if persisted.nil?

      persisted.graph
    end

    def statements
      return [] if graph.nil?

      graph.statements
    end

    ##
    # Have we retrieved the content already?
    def retrieved_content?
      !@http_response.nil?
    end

    ##
    # Get the resource
    # rubocop:disable Naming/AccessorMethodName
    def get_request
      @http_response = client.get(subject)
    end
    # rubocop:enable Naming/AccessorMethodName

    # Legacy
    def get
      get_request
    end

    ##
    # Delete the resource
    def delete
      return if new?

      persisted.destroy
    end

    # Legacy
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
    def create(&block)
      raise(Ldp::Conflict, "Can't call create on an existing resource (#{subject})") unless new?

      if client.repository
        built = self.class.rdf_ldp_class.new(subject)
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

    def current?(cached_response = nil)
      cached_response ||= @http_response
      return true if new? and subject.nil?

      # new_response = client.head(subject)
      new_response = head_request

      # return false unless response.headers['ETag']
      # return false unless response.headers['Last-Modified']

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

      @http_response.etag = cached_response.etag
      @http_response.last_modified = cached_response.last_modified
    end

    protected

    def interaction_model
      nil
    end
  end
end
