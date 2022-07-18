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

      @subject = if subject.nil?
                   subject
                 else
                   parsed_subject = URI.parse(subject)
                   if parsed_subject.host.nil?
                     base_segment = base_path.chomp("/")
                     subject_segment = subject.gsub(/^\//, "")
                     [base_segment, subject_segment].join("/")
                   else
                     subject
                   end
                 end

      @get = response if response.is_a? Faraday::Response and current? response
      @base_path = base_path
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      @subject_uri ||= RDF::URI(subject)
    end

    def root?
      subject_uri.to_s == "/"
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
      # verb = new? ? :post : :put
      verb = new? ? :put : :post

      create_content = content

      request_url = subject || @base_path

      create_headers = {}
      create_headers["Link"] = "<#{interaction_model}>;rel=\"type\"" if interaction_model
      request_headers = default_create_headers.merge(create_headers)

      resp = client.send(verb, request_url, create_content, request_headers) do |req|
        # This is no longer being passed
        # req.headers["Link"] = "<#{interaction_model}>;rel=\"type\"" if interaction_model
        # req.headers = default_create_headers.merge(req.headers)

        yield req if block_given?
      end

      @subject = resp.headers['Location']
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
