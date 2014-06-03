require 'spec_helper'

describe Ldp::Response do
  LDP_RESOURCE_HEADERS = { "Link" => "<#{Ldp.resource.to_s}>;rel=\"type\""}

  let(:mock_response) { double(headers: {}, env: { url: "info:a" }) }
  let(:mock_client) { double(Ldp::Client) }

  subject do
    Ldp::Response.wrap mock_client, mock_response
  end

  describe ".wrap" do
    it "should mixin Ldp::Response into the raw response" do
      Ldp::Response.wrap(mock_client, mock_response)
      expect(mock_response).to be_a_kind_of(Ldp::Response)
    end
  end

  describe ".links" do
    it "should extract link headers with relations as a hash" do
      mock_response.stub(:headers => { 
        "Link" => [
            "<xyz>;rel=\"some-rel\"",
            "<abc>;rel=\"some-multi-rel\"",
            "<123>;rel=\"some-multi-rel\"",
            "<vanilla-link>"
          ] 
        })
      h = Ldp::Response.links mock_response

      expect(h['some-rel']).to include("xyz")
      expect(h['some-multi-rel']).to include("abc", "123")
      expect(h['doesnt-exist']).to be_nil
    end

    it "should return an empty hash if no link headers are availabe" do
      mock_response.stub(:headers => {})
      h = Ldp::Response.links mock_response

      expect(h).to be_empty
    end

  end

  describe ".resource?" do
    it "should be a resource if a Link[rel=type] header asserts it is an ldp:resource" do
      mock_response.stub(:headers => { 
        "Link" => [
            "<#{Ldp.resource}>;rel=\"type\""
          ] 
      })
      expect(Ldp::Response.resource? mock_response).to be_truthy
    end
  end

  describe "#graph" do
    it "should parse the response body for an RDF graph" do
      mock_response.stub :body => "<> <info:b> <info:c> .", :headers => LDP_RESOURCE_HEADERS
      graph = subject.graph
     
      expect(graph).to have_subject(RDF::URI.new("info:a")) 
      expect(graph).to have_statement RDF::Statement.new(RDF::URI.new("info:a"), RDF::URI.new("info:b"), RDF::URI.new("info:c"))

    end
  end

  describe "#etag" do
    it "should pass through the response's ETag" do
      mock_response.stub :headers => { 'ETag' => 'xyz'}

      expect(subject.etag).to eq('xyz')
    end
  end

  describe "#last_modified" do
    it "should pass through the response's Last-Modified" do
      mock_response.stub :headers => { 'Last-Modified' => 'some-date'}
      expect(subject.last_modified).to eq('some-date')
    end
  end

  describe "#has_page" do
    it "should see if the response has an ldp:Page statement" do
      graph = RDF::Graph.new

      graph << [RDF::URI.new('info:a'), RDF.type, Ldp.page]

      mock_response.stub :body => graph.dump(:ttl), :headers => LDP_RESOURCE_HEADERS

      expect(subject).to have_page
    end

    it "should be false otherwise" do
      subject.stub :page_subject => RDF::URI.new('info:a')
      mock_response.stub :body => '', :headers => LDP_RESOURCE_HEADERS
      expect(subject).not_to have_page
    end
  end

  describe "#page" do
    it "should get the ldp:Page data from the query" do
      graph = RDF::Graph.new

      graph << [RDF::URI.new('info:a'), RDF.type, Ldp.page]
      graph << [RDF::URI.new('info:b'), RDF.type, Ldp.page]

      mock_response.stub :body => graph.dump(:ttl), :headers => LDP_RESOURCE_HEADERS

      expect(subject.page.count).to eq(1)
   
    end
  end

  describe "#subject" do
    it "should extract the HTTP request URI as an RDF URI" do
      mock_response.stub :body => '', :headers => LDP_RESOURCE_HEADERS
      mock_response.stub :env => { :url => 'http://xyz/a'}
      expect(subject.subject).to eq(RDF::URI.new("http://xyz/a"))
    end
  end
end
