module Ldp
  class Resource
    require 'ldp/resource/binary_source'
    require 'ldp/resource/rdf_source'

    attr_reader :client, :subject
    attr_accessor :content

    def initialize client, subject, response = nil, base_path = ''
      @client = client
      @subject = subject
      @get = response if response.is_a? Faraday::Response and current? response
      @base_path = base_path
    end

    ##
    # Get the graph subject as a URI
    def subject_uri
      @subject_uri ||= RDF::URI.new subject
    end

    ##
    # Reload the LDP resource
    def reload
      self.class.new client, subject, @get
    end

    ##
    # Is the resource new, or does it exist in the LDP server?
    def new?
      subject.nil? || head == None
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

    def head
      @head ||= begin
        @get || client.head(subject)
      rescue Ldp::NotFound
        None
      end
    end

    ##
    # Delete the resource
    def delete
      client.delete subject do |req|
        req.headers['If-Match'] = get.etag if retrieved_content?
      end
    end

    def save
      new? ? create : update
    end

    ##
    # Create a new resource at the URI
    # @return [RdfSource] the new representation
    def create &block
      raise "Can't call create on an existing resource" unless new?
      verb = subject.nil? ? :post : :put
      resp = client.send(verb, (subject || @base_path), content) do |req|

        yield req if block_given?
      end

      @subject = resp.headers['Location']
      @subject_uri = nil
      reload
    end

    ##
    # Update the stored graph
    def update new_content = nil
      new_content ||= content
      resp = client.put subject, new_content do |req|
        req.headers['If-Match'] = get.etag if retrieved_content?
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

    def update_cached_get response
      Response.wrap(client, response)
      if response.etag.nil? || response.last_modified.nil?
        response = Response.wrap(client, client.head(subject))
      end
      @get.etag = response.etag
      @get.last_modified = response.last_modified
    end

  end
end
