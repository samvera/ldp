module Ldp::Client::Methods
  def logger
    Ldp.logger
  end

  # Get a LDP Resource by URI
  def get url
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
    http.delete do |req|
      req.url url
      yield req if block_given?
    end
  end

  # Post TTL to an LDP Resource
  def post url, body = nil, headers = {}
    logger.debug "POST [#{url}] #{body}"
    http.post do |req|
      req.url url
      req.headers = {"Content-Type"=>"text/turtle"}.merge headers
      req.body = body
      yield req if block_given?
    end
  end

  # Update an LDP resource with TTL by URI
  def put url, body
    logger.debug "PUT [#{url}] #{body}"
    http.put do |req|
      req.url url
      req.headers['Content-Type'] = 'text/turtle'
      req.body = body
      yield req if block_given?
    end
  end
end
