module Ldp::Uri

  def uri str
    RDF::URI.new("http://www.w3.org/ns/ldp#") + str
  end

  def resource
    uri("Resource")
  end

  def container
    uri("Container")
  end

  def page
    uri("Page")
  end

  def page_of
    uri("pageOf")
  end

  def next_page
    uri("nextPage")
  end

  def inlinedResource
    uri("inlinedResource")
  end

  def membership_predicate
    uri("membershipPredicate")
  end

end