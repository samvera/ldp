require "rdf/ldp"

module Ldp
  class Resource
    require "ldp/resource/binary_source"
    require "ldp/resource/rdf_source"

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

    ##
    # Get the graph subject as a URI
    # Legacy
    attr_reader :subject

    def initialize(client, subject, http_response = nil, base_path = "")
      @client = client
      @subject = subject || default_subject
      @http_response = http_response if http_response.is_a?(Faraday::Response) && current?(http_response)
      @base_path = base_path
    end

    def default_subject
      value = self.class.build_subject_uri(value: "", client: client)
      RDF::URI.parse(value)
    end

    def subject_uri
      @subject_uri ||= begin
                         value = self.class.build_subject_uri(value: @subject, client: client)
                         RDF::URI.parse(value)
                       end
    end

    alias uri subject
    alias to_uri uri

    ##
    # Reload the LDP resource
    def reload
      self.class.new(client, subject)
    end

    def head_request!
      @head_response ||= client.head(subject_uri)
    end
    alias head! head_request! # Legacy support

    def head_request
      head_request!
    rescue Ldp::NotFound
      nil
    rescue Ldp::Gone
      nil
    end

    # Legacy Support
    def head
      head_request!
    rescue Ldp::NotFound
      Ldp::None
    end

    def persisted?
      !persisted.nil?
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      !persisted?
    end

    def repository
      client.repository || RDF::Repository.new
    end

    def persisted
      @persisted ||= find
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
    def cached?
      !get_response.nil?
    end
    # Legacy support
    alias retrieved_content? cached?

    ##
    # Get the resource
    # rubocop:disable Naming/AccessorMethodName
    def get_request!
      raise(Ldp::NotFound) unless persisted?

      @http_response = client.get(subject)
    end
    # rubocop:enable Naming/AccessorMethodName

    # Legacy
    alias get get_request!

    # rubocop:disable Naming/AccessorMethodName
    def get_request
      get_request!
    rescue RDF::LDP::NotFound
      nil
    end
    # rubocop:enable Naming/AccessorMethodName

    # rubocop:disable Naming/AccessorMethodName
    def get_response
      @http_response
    end
    # rubocop:enable Naming/AccessorMethodName

    def last_modified
      return unless persisted?

      return unless cached?
      get_request.last_modified
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
        @persisted = built.create(content, "application/n-triples")

        @subject_uri = @persisted.subject_uri
        @subject = @subject_uri.to_s
      else
        # Legacy support
        verb = subject.nil? ? :post : :put
        resp = client.send(verb, (subject || @base_path), content) do |req|
          req.headers["Link"] = "<#{interaction_model}>;rel=\"type\"" if interaction_model
          yield req if block_given?
        end

        @subject = resp.headers["Location"]
        @subject_uri = nil
        reload
      end
    end

    def content_type
      "text/turtle"
    end

    ##
    # Update the stored graph
    def update(new_content = nil, &block)
      new_content ||= content

      persisted.update(new_content, content_type, &block)

      response = client.put subject_uri, new_content do |request|
        request.headers["If-Unmodified-Since"] = last_modified if cached?
        yield request if block_given?
      end

      update_cached_get(response) if retrieved_content?
      response
    end

    def current?(cached_response = nil)
      cached_response ||= get_response
      return true if new? and subject.nil?

      # new_response = client.head(subject)
      new_response = head_request

      # return false unless response.headers['ETag']
      # return false unless response.headers['Last-Modified']

      return false unless new_response.headers["ETag"] == cached_response.headers["ETag"]
      return false unless new_response.headers["Last-Modified"] == cached_response.headers["Last-Modified"]

      true
    end

    # Updates the `E-tag` and `last-modified` header values for the resource
    def update_cached_get(cached_response)
      cached_response = Response.new(cached_response)

      if cached_response.etag.nil? || cached_response.last_modified.nil?
        cached_response = head_request
      end

      get_response.etag = cached_response.etag
      get_response.last_modified = cached_response.last_modified
    end

    private

    def find
      RDF::LDP::Resource.find(subject, repository)
    rescue RDF::LDP::NotFound
      nil
    end

    protected

    def interaction_model
      nil
    end
  end
end
