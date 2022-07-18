##
# LDP client for presenting an ORM on top of an LDP resource
module Ldp
  class Client
    require 'ldp/client/methods'
    require 'ldp/client/prefer_headers'
    include Ldp::Client::Methods

    attr_reader :options

    def self.default_client_url
      "#{ENV['FCREPO_SCHEME']}://#{ENV['FCREPO_HOST']}:#{ENV['FCREPO_PORT']}/rest/"
    end

    def self.default_http_client
      Faraday.new(url: default_client_url)
    end

    def self.default
      new(default_http_client)
    end

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

      initialize_http_client(http_client || options)
    end

    # Find or initialize a new LDP resource by URI
    def find_or_initialize(subject, options = {})
      subject_uri = URI.parse(subject)
      request_url = if subject_uri.host.nil?
                      base_segment = @http.url_prefix.to_s.chomp("/")
                      subject_segment = if /^\//.match?(subject)
                                          subject
                                        else
                                          "/#{subject}"
                                        end
                      "#{base_segment}#{subject_segment}"
                    else
                      subject
                    end
      data = get(request_url, options)

      Ldp::Resource.for(self, request_url, data)
    rescue Ldp::NotFound
      nil
    rescue Ldp::Gone
      nil
    end

    def logger
      Ldp.logger
    end
  end
end
