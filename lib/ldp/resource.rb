module Ldp
  class Resource
    require 'ldp/resource/binary_source'
    require 'ldp/resource/rdf_source'

    attr_reader :client, :subject
    attr_accessor :content

    def self.for(client, subject, response, base_path = '')
      case
      when response.container?
        Ldp::Container.for(client, subject, response, base_path)
      when response.rdf_source?
        Resource::RdfSource.new(client, subject, response, base_path)
      else
        Resource::BinarySource.new(client, subject, response, base_path)
      end
    end

    def initialize(client, subject, response = nil, base_path = '')
      @client = client

      @base_path = if base_path.empty?
                     nil
                   else
                     base_path
                   end

      @subject = if subject.nil?
                   subject
                 else
                   parsed_subject = URI.parse(subject)
                   if parsed_subject.host.nil? && !@base_path.nil?
                     base_segment = base_path.chomp("/")
                     subject_segment = subject.gsub(/^\//, "")
                     [base_segment, subject_segment].join("/")
                   else
                     subject
                   end
                 end

      @get = response if response.is_a? Faraday::Response and current? response
    end

    def base_url
      return if @base_path.nil?

      @base_url ||= URI(@base_path)
    end

    def base_uri
      return if base_url.nil?

      @base_uri ||= URI(base_uri)
    end

    def subject_url
      return if subject.nil?

      @subject_url ||= URI(subject)
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      return if subject_url.nil?

      @subject_uri ||= RDF::URI(subject_url)
    end

    def root?
      subject_uri.path.nil? || subject_uri.path == "/" || subject_uri.path == base_uri.path
    end

    ##
    # Reload the LDP resource
    def reload
      self.class.new(client, subject, @get)
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      subject.nil? || head == None
    end

    ##
    # Have we retrieved the content already?
    def retrieved_content?
      !!@get
    end

    ##
    # Get the resource
    def get
      @get ||= client.get(subject)
    rescue Ldp::Gone
      None
    end

    def head
      @head ||= begin
                  @get || client.head(subject)
                rescue Ldp::NotFound
                  None
                rescue Ldp::Gone
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

    def default_create_headers
      {}
    end

    ##
    # Create a new resource at the URI
    # @return [RdfSource] the new representation
    # @raise [Ldp::Conflict] if you attempt to call create on an existing resource
    def create &block
      raise Ldp::Conflict, "Can't call create on an existing resource (#{subject})" unless new?

      create_content = content

      create_headers = {}
      create_headers["Link"] = "<#{interaction_model}>;rel=\"type\"" if interaction_model
      request_headers = default_create_headers.merge(create_headers)

      if subject.nil?
        request_url = base_url
        verb = :post
      else
        request_url = subject_url
        verb = :put
      end

      response = client.send(verb, request_url, create_content, request_headers) do |request|
        # Headers are no longer being passed in the request when set here
        yield request if block_given?
      end

      @subject = response.headers['Location']
      subject_uri
      reload
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

    def current? response = nil
      response ||= @get
      return true if new? and subject.nil?

      new_response = client.head(subject)

      response.headers['ETag'] &&
        response.headers['Last-Modified'] &&
        new_response.headers['ETag'] == response.headers['ETag'] &&
        new_response.headers['Last-Modified'] == response.headers['Last-Modified']
    end

    def update_cached_get(response)
      response = Response.new(response)

      if response.etag.nil? || response.last_modified.nil?
        response = client.head(subject)
      end
      @get.etag = response.etag
      @get.last_modified = response.last_modified
    end

    protected

    def interaction_model
      nil
    end
  end
end
