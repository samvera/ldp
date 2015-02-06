require 'faraday'

##
# HTTP client methods for making requests to an LDP resource and getting a response back.
module Ldp::Client::Methods

  attr_reader :http
  def initialize_http_client *http_client
    if http_client.length == 1 and http_client.first.is_a? Faraday::Connection
      @http = http_client.first
    else
      @http = Faraday.new *http_client
    end
  end

  def head url
    logger.debug "LDP: HEAD [#{url}]"
    resp = http.head do |req|
      req.url munge_to_relative_url(url)

      yield req if block_given?
    end

    check_for_errors(resp)
  end

  # Get a LDP Resource by URI
  def get url, options = {}
    logger.debug "LDP: GET [#{url}]"
    resp = http.get do |req|
      req.url munge_to_relative_url(url)

      if options[:minimal]
        req.headers["Prefer"] = "return=minimal"
      else
        includes = Array(options[:include]).map { |x| Ldp.send("prefer_#{x}") if Ldp.respond_to? "prefer_#{x}" }
        omits = Array(options[:omit]).map { |x| Ldp.send("prefer_#{x}") if Ldp.respond_to? "prefer_#{x}" }
        req.headers["Prefer"] = ["return=representation",
          ("include=\"#{includes.join(" ")}\"" unless includes.empty?),
          ("omit=\"#{omits.join(" ")}\"" unless omits.empty?)
        ].compact.join("; ")
      end

      yield req if block_given?
    end

    if Ldp::Response.resource? resp
      Ldp::Response.wrap self, resp
    else
      resp
    end

    check_for_errors(resp)
  end

  # Delete a LDP Resource by URI
  def delete url
    logger.debug "LDP: DELETE [#{url}]"
    resp = http.delete do |req|
      req.url munge_to_relative_url(url)
      yield req if block_given?
    end

    check_for_errors(resp)
  end

  # Post TTL to an LDP Resource
  def post url, body = nil, headers = {}
    logger.debug "LDP: POST [#{url}]"
    resp = http.post do |req|
      req.url munge_to_relative_url(url)
      req.headers.merge!(default_headers).merge!(headers)
      req.body = body
      yield req if block_given?
    end
    check_for_errors(resp)
  end

  # Update an LDP resource with TTL by URI
  def put url, body, headers = {}
    logger.debug "LDP: PUT [#{url}]"
    resp = http.put do |req|
      req.url munge_to_relative_url(url)
      req.headers.merge!(default_headers).merge!(headers)
      req.body = body
      yield req if block_given?
    end
    check_for_errors(resp)
  end

  # Update an LDP resource with TTL by URI
  def patch url, body, headers = {}
    logger.debug "LDP: PATCH [#{url}]"
    resp = http.patch do |req|
      req.url munge_to_relative_url(url)
      req.headers.merge!(default_patch_headers).merge!(headers)
      req.body = body
      yield req if block_given?
    end
    check_for_errors(resp)
  end
  private

  def check_for_errors resp
    resp.tap do |resp|
      unless resp.success?
        raise case resp.status
          when 400
            if resp.env.method == :head
              # If the request was a HEAD request (which only retrieves HTTP headers),
              # re-run it as a GET in order to retrieve a message body (which is passed on as the error message)
              get(resp.env.url.path)
            else
              Ldp::BadRequest.new(resp.body)
            end
          when 404
            Ldp::NotFound.new(resp.body)
          when 410
            Ldp::Gone.new(resp.body)
          when 412
            Ldp::EtagMismatch.new(resp.body)
          else
            Ldp::HttpError.new("STATUS: #{resp.status} #{resp.body[0, 1000]}...")
          end
      end
    end
  end

  def default_headers
    {"Content-Type"=>"text/turtle"}
  end

  def default_patch_headers
    {"Content-Type"=>"application/sparql-update"}
  end
  ##
  # Some valid query paths can be mistaken for absolute URIs
  # with an alternative scheme. If the scheme isn't HTTP(S), assume
  # they meant a relative URI instead.
  def munge_to_relative_url url
    purl = URI.parse(url)
    if purl.absolute? and !((purl.scheme rescue nil) =~ /^http/)
      "./" + url
    else
      url
    end
  end
end
