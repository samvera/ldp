require "faraday"

##
# HTTP client methods for making requests to an LDP resource and getting a response back.
module Ldp::Client::Methods
  def head(value)
    response = http.head do |request|
      url = build_url(value)
      request.url(url)

      yield request if block_given?
    end

    check_for_errors(response)

    Ldp::Response.new(response)
  end

  # Get a LDP Resource by URI
  def get(value, options = {})
    url = build_url(value)
    prefer_headers = ::Ldp::PreferHeaders.new

    response = http.get do |request|
      if options[:minimal]
        prefer_headers.return = "minimal"
      else
        prefer_headers.return = "representation"
        includes = Array(options[:include]).map { |x| Ldp.send("prefer_#{x}") if Ldp.respond_to? "prefer_#{x}" }
        omits = Array(options[:omit]).map { |x| Ldp.send("prefer_#{x}") if Ldp.respond_to? "prefer_#{x}" }
        prefer_headers.include = includes
        prefer_headers.omit = omits
      end
      request.headers["Prefer"] = prefer_headers.to_s
      request.url(url)

      yield request if block_given?
    end

    check_for_errors(response)

    Ldp::Response.new(response)
  end

  # Delete a LDP Resource by URI
  def delete(value)
    url = build_url(value)

    response = http.delete do |request|
      request.url(url)

      yield request if block_given?
    end

    check_for_errors(response)
  end

  # Post TTL to an LDP Resource
  def post(value, body = nil, headers = {})
    url = build_url(value)
    request_headers = default_headers.merge(headers)

    response = http.post do |request|
      request.url(url)
      request.headers.merge!(request_headers)
      request.body = body

      yield request if block_given?
    end

    check_for_errors(response)
  end

  # Update an LDP resource with TTL by URI
  def put(value, body, headers = {})
    url = build_url(value)
    request_headers = default_headers.merge(headers)

    response = http.put do |request|
      request.url(url)
      request.headers.merge!(request_headers)
      request.body = body
      yield request if block_given?
    end

    check_for_errors(response)
  end

  # Update an LDP resource with TTL by URI
  def patch(value, body, headers = {})
    url = build_url(value)
    request_headers = default_headers.merge(headers)

    response = http.patch do |request|
      request.url munge_to_relative_url(url)
      request_headers = default_headers.merge(headers)
      request.body = body
      yield request if block_given?
    end

    check_for_errors(response)
  end

  private

  def check_for_errors response
    response.tap do |resp|
      unless resp.status < 400
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
              when 409
                Ldp::Conflict.new(resp.body)
              when 410
                Ldp::Gone.new(resp.body)
              when 412
                Ldp::PreconditionFailed.new(resp.body)
              else
                Ldp::HttpError.new("STATUS: #{resp.status} #{resp.body[0, 1000]}...")
              end
      end
    end
  end

  def default_headers
    { "Content-Type" => "text/turtle" }
  end

  def default_patch_headers
    { "Content-Type" => "application/sparql-update" }
  end

  ##
  # Some valid query paths can be mistaken for absolute URIs
  # with an alternative scheme. If the scheme isn't HTTP(S), assume
  # they meant a relative URI instead.
  def munge_to_relative_url_dep url
    purl = build_url(uri: url)

    if purl.absolute? and !((purl.scheme rescue nil) =~ /^http/)
      "./" + url
    else
      url
    end
  end

  # Make this a class method
  def build_url(value)
    uri = URI.parse(value)

    if uri.opaque
      value = "/#{value}" unless value.chars.first == "/"
      protocol = if uri.scheme == "https"
                   "https:"
                 else
                   "http:"
                 end
      uri = URI.parse("#{protocol}//#{host}:#{port}#{value}")
    else
      uri.path = "/#{uri.path}" unless uri.path.chars.first == "/"
      uri.host = host if uri.host.nil?
      uri.port = port if uri.port.nil?
    end

    # Default to HTTP (this is for legacy support)
    if uri.scheme == "https"
      URI::HTTPS.build(host: uri.host, port: uri.port, path: uri.path, query: uri.query, fragment: uri.fragment)
    else
      URI::HTTP.build(host: uri.host, port: uri.port, path: uri.path, query: uri.query, fragment: uri.fragment)
    end
  end

  # Legacy support
  def munge_to_relative_url(value)
    build_url(value)
  end
end
