require 'ldp/version'

module Ldp
  require 'ldp/client'

  def self.uri str
    RDF::URI.new("http://www.w3.org/ns/ldp#") + str
  end

  def self.resource
    uri("Resource")
  end

  def self.container
    uri("Container")
  end

  def self.page
    uri("Page")
  end

  def self.page_of
    uri("pageOf")
  end

  def self.next_page
    uri("nextPage")
  end

  def self.inlinedResource
    uri("inlinedResource")
  end

  def self.membership_predicate
    uri("membershipPredicate")
  end

  autoload :Response, 'ldp/response'
  autoload :Resource, 'ldp/resource'
  autoload :Container, 'ldp/container'
end