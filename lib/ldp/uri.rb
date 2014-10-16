module Ldp::Uri

  def uri str
    RDF::URI.new("http://www.w3.org/ns/ldp#") + str
  end

  def resource
    uri("Resource")
  end

  def rdf_source
    uri("RDFSource")
  end

  def non_rdf_source
    uri("NonRDFSource")
  end

  def container
    uri("Container")
  end

  def basic_container
    uri("BasicContainer")
  end

  def direct_container
    uri("DirectContainer")
  end

  def indirect_container
    uri("IndirectContainer")
  end

  def contains
    uri("contains")
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

  def membership_predicate
    uri("membershipPredicate")
  end
  
  def prefer_empty_container
    uri("PreferEmptyContainer")
  end
  
  def prefer_membership
    uri("PreferMembership")
  end
  
  def prefer_containment
    uri("PreferContainment")
  end
  
  def has_member_relation
    uri("hasMemberRelation")
  end
  
  def member
    uri("member")
  end

end
