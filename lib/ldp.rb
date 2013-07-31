require 'ldp/version'

module Ldp
  require 'ldp/client'

  def self.resource
    RDF::URI.new("http://www.w3.org/ns/ldp/Resource")
  end

  def self.container
    RDF::URI.new("http://www.w3.org/ns/ldp/Container")
  end

  def self.inlinedResource
    RDF::URI.new("http://www.w3.org/ns/ldp/inlinedResource")
  end

  autoload :Response, 'ldp/response'
  autoload :Resource, 'ldp/resource'
  autoload :Container, 'ldp/container'
end