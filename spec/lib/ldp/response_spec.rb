require 'spec_helper'

describe Ldp::Response do

  let(:mock_response) { double() }
  let(:mock_client) { double(Ldp::Client) }

  subject do
    Ldp::Response.wrap mock_client, mock_response
  end

  describe ".wrap" do
    it "should mixin Ldp::Response into the raw response" do
      Ldp::Response.wrap(mock_client, mock_response)
      expect(mock_response).to be_a_kind_of(Ldp::Response)
      expect(mock_response.ldp_client).to eq(mock_client)
    end
  end

  describe ".links" do
    it "should extract link headers with relations as a hash" do
      mock_response.stub(:headers => { 
        "Link" => [
            "xyz;rel=\"some-rel\"",
            "abc;rel=\"some-multi-rel\"",
            "123;rel=\"some-multi-rel\"",
            "vanilla-link"
          ] 
        })
      h = Ldp::Response.links mock_response

      expect(h['some-rel']).to include("xyz")
      expect(h['some-multi-rel']).to include("abc", "123")
      expect(h['doesnt-exist']).to be_empty
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
            "#{Ldp.resource};rel=\"type\""
          ] 
      })
      expect(Ldp::Response.resource? mock_response).to be_true
    end
  end

  describe "#graph" do
    it "should parse the response body for an RDF graph" do
      mock_response.stub :body => "<> <b> <c>"
      subject.stub :subject => RDF::URI.new('a')
      graph = subject.graph

      expect(graph).to have_subject(RDF::URI.new("a")) 
      expect(graph).to have_statement RDF::Statement.new(RDF::URI.new("a"), RDF::URI.new("b"), RDF::URI.new("c"))

    end
  end

  describe "#subject" do
    it "should extract the HTTP request URI as an RDF URI" do
      mock_response.stub :env => { :url => 'a'}
      expect(subject.subject).to eq(RDF::URI.new("a"))
    end
  end
end
