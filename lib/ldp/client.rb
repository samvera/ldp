##
# LDP client for presenting an ORM on top of an LDP resource
module Ldp
  class Client
    require 'ldp/client/methods'
    require 'ldp/client/prefer_headers'
    include Ldp::Client::Methods

    attr_reader :http, :options, :repository

    def initialize(*args)
      http_client, options = if args.length == 2
                               args
                             elsif args.length == 1 && args.first.is_a?(Faraday::Connection)
                               [args.first, {}]
                             elsif args.length == 1
                               [nil, args.first]
                             else
                               raise ArgumentError
                             end

      @options = options
      @repository = options.fetch(:repository, nil)

      initialize_http_client(http_client || options)
    end

    delegate :host, :port, to: :http

    # Find or initialize a new LDP resource by URI
    def find_or_initialize(subject, options = {})
      data = get(subject, options)

      Ldp::Resource.for(self, subject, data)
    end

    def logger
      Ldp.logger
    end

    private

    def initialize_http_client(*http_client)
      @http = if (http_client.length == 1) && http_client.first.is_a?(Faraday::Connection)
                http_client.first
              else
                Faraday.new(*http_client)
              end
    end
  end
end
