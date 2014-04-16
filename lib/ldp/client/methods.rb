##
# HTTP client methods for making requests to an LDP resource and getting a response back.
module Ldp::Client::Methods
  def logger
    Ldp.logger
  end

  # Get a LDP Resource by URI
  def get url, options = {}
    logger.debug "LDP: GET [#{url}]"
    resp = http.get do |req|                          
      req.url url
      yield req if block_given?
    end

    if Ldp::Response.resource? resp
      Ldp::Response.wrap self, resp
    else
      resp
    end
  end

  # Delete a LDP Resource by URI
  def delete url
    logger.debug "LDP: DELETE [#{url}]"
    http.delete do |req|
      req.url url
      yield req if block_given?
    end
  end

  # Post TTL to an LDP Resource
  def post url, body = nil, headers = {}
    logger.debug "LDP: POST [#{url}]"
    http.post do |req|
      req.url url
      req.headers = default_headers.merge headers
      req.body = body
      yield req if block_given?
    end
  end

  # Update an LDP resource with TTL by URI
  def put url, body, headers = {}
    logger.debug "LDP: PUT [#{url}]"
    http.put do |req|
      req.url url
      req.headers = default_headers.merge headers
      req.body = body
      yield req if block_given?
    end
  end

  private

  def default_headers
    {"Content-Type"=>"text/turtle"}
  end
end
