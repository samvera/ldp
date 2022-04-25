require 'spec_helper'
require 'rdf/vocab'
require 'rdf/ldp'

describe Ldp::Orm do
  subject { Ldp::Orm.new test_resource }

  let(:subject_uri) do
    RDF::URI.new("http://localhost/a_resource")
  end

  let(:simple_graph) do
    RDF::Graph.new << [subject_uri, RDF::Vocab::DC.title, "Hello, world!"]
  end

  let(:conn_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.put(subject_uri.to_s) { [204]}
      stub.get(subject_uri.to_s) {[ 200, {"Link" => "<http://www.w3.org/ns/ldp#DirectContainer>;rel=\"type\", <http://www.w3.org/ns/ldp#Resource>;rel=\"type\""}, simple_graph.dump(:ttl) ]}
      stub.head(subject_uri.to_s) { [200] }
    end
  end

  let(:mock_conn) do
    Faraday.new do |builder|
      builder.adapter :test, conn_stubs do |stub|
      end
    end
  end

  let :mock_client do
    Ldp::Client.new mock_conn
  end

  let :test_resource do
    Ldp::Resource::RdfSource.new(mock_client, subject_uri)
  end

  describe "#delete" do
    it "should delete the LDP resource" do
      expect(test_resource).to receive(:delete)
      subject.delete
    end
  end

  describe "#create" do
    let(:conn_stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.head(subject_uri.to_s) { [404]}
        stub.post(subject_uri.to_s) do [
            201,
            {
              "Link" => "<http://www.w3.org/ns/ldp#DirectContainer>;rel=\"type\", <http://www.w3.org/ns/ldp#Resource>;rel=\"type\""
            },
            simple_graph.dump(:ttl)
          ]
        end
        stub.put(subject_uri.to_s) { [204]}
      end
    end

    let(:mock_conn) do
      Faraday.new do |builder|
        builder.adapter :test, conn_stubs do |stub|
        end
      end
    end

    let(:simple_graph) do
      RDF::Graph.new << [RDF::URI.new("http://localhost/a_resource"), RDF::Vocab::DC.title, "Hello, world!"]
    end

    let :test_resource do
      Ldp::Resource::RdfSource.new(mock_client, nil, simple_graph)
    end

    before do
      #stub_request(:head, "/a_resource").
      #  to_return(status: 200)
    end

    it "should return a new orm" do
      expect(subject.create).to be_kind_of Ldp::Orm
    end
  end

  describe "#save" do
    it "should update the resource from the graph" do
      expect(subject.save).to be true
    end

    it "should return false if the response was not successful" do
      conn_stubs.instance_variable_get(:@stack)[:put] = [] # erases the stubs for :put

      conn_stubs.put(subject_uri.to_s) {[412, nil, 'There was an error']}
      expect(subject.save).to be false
    end
  end

  describe "#save!" do
    it "should raise an exception if the ETag didn't match" do
      conn_stubs.instance_variable_get(:@stack)[:put] = [] # erases the stubs for :put

      conn_stubs.put(subject_uri.to_s) {[412, {}, "Bad If-Match header value: 'ae43aa934dc4f4e15ea1b4dd1ca7a56791972836'"]}
      expect { subject.save! }.to raise_exception(Ldp::PreconditionFailed, "Bad If-Match header value: 'ae43aa934dc4f4e15ea1b4dd1ca7a56791972836'")
    end
  end

  describe "#value" do
    let(:subject_uri) do
      RDF::URI.new("http://example.com/a_resource")
    end

    let(:conn_stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get(subject_uri.to_s) {[ 200, {"Link" => "<http://www.w3.org/ns/ldp#DirectContainer>;rel=\"type\", <http://www.w3.org/ns/ldp#Resource>;rel=\"type\""}, simple_graph.dump(:ttl) ]}
        stub.head(subject_uri.to_s) { [200] }
      end
    end

    let(:ldp_resource_model) { double }

    before do
      allow(ldp_resource_model).to receive(:graph).and_return(simple_graph)
      allow(RDF::LDP::Resource).to receive(:find).and_return(ldp_resource_model)
    end

    it "should provide a convenience method for retrieving values" do
      expect(subject.value(RDF::Vocab::DC.title).first.to_s).to eq "Hello, world!"
    end
  end

  describe "#reload" do
    let(:ldp_resource_model) { double }
    let(:updated_subject_uri) { RDF::URI.new("http://localhost/a_resource") }
    let(:updated_graph) { RDF::Graph.new << [updated_subject_uri, RDF::Vocab::DC.title, "Hello again, world!"] }

    before do
      allow(ldp_resource_model).to receive(:graph).and_return(simple_graph, updated_graph)
      allow(RDF::LDP::Resource).to receive(:find).and_return(ldp_resource_model)
    end

    before do
      conn_stubs.get(subject_uri.to_s) do
        [
          200,
          {
            "Link" => "<http://www.w3.org/ns/ldp#Resource>;rel=\"type\", <http://www.w3.org/ns/ldp#DirectContainer>;rel=\"type\"",
            "ETag" => "new-tag"
          },
          updated_graph.dump(:ttl)
        ]
      end
    end

    it "loads the new values" do
      old_value = subject.value(RDF::Vocab::DC.title).first.to_s
      reloaded = subject.reload
      expect(reloaded.value(RDF::Vocab::DC.title).first.to_s).not_to eq old_value
    end

    it "uses the new ETag" do
      old_tag = subject.resource.get.etag
      reloaded = subject.reload
      expect(reloaded.resource.get.etag).not_to eq old_tag
    end
  end
end
