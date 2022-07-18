require 'spec_helper'

describe Ldp::Orm do
  subject { Ldp::Orm.new test_resource }

  let(:simple_graph) do
    RDF::Graph.new << [RDF::URI.new(""), RDF::Vocab::DC.title, "Hello, world!"]
  end

  before do
    stub_request(:get, "#{client_url}/a_resource").to_return( status: 200, headers: {
      "Link" => ["<http://www.w3.org/ns/ldp#DirectContainer>;rel=\"type\"", "<http://www.w3.org/ns/ldp#Resource>;rel=\"type\""],
    }, body: simple_graph.dump(:ttl) )
    stub_request(:head, "#{client_url}/a_resource").to_return( status: 200, headers: {} )
    stub_request(:put, "#{client_url}/a_resource").to_return( status: 204, headers: {} )

    stub_request(:head, "#{client_url}/a_test_resource").to_return( status: 404, headers: {} )
    stub_request(:put, "#{client_url}/a_test_resource").to_return( status: 201, headers: {} )
  end

  let(:client_url) { "http://example.com" }
  let(:resource_subject) { "a_test_resource" }

  let(:mock_conn) do
    #Faraday.new do |builder|
    #  builder.adapter :test, conn_stubs do |stub|
    #  end
    #end
    Faraday.new(url: client_url)
  end

  let :mock_client do
    Ldp::Client.new mock_conn
  end

  let :test_resource do
    Ldp::Resource::RdfSource.new mock_client, "http://example.com/a_resource"
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
        stub.post("/") { [201]}
      end
    end
    let :test_resource do
      Ldp::Resource::RdfSource.new(mock_client, resource_subject, simple_graph)
    end
    it "should return a new orm" do
      expect(subject.create).to be_kind_of Ldp::Orm
    end
  end

  describe "#save" do
    it "should update the resource from the graph" do
      expect(subject.save).to be true
    end

    context "when the response was not successful" do
      before do
        stub_request(:put, "#{client_url}/a_resource").to_return( status: 412, headers: {}, body: "There was an error" )
      end

      it "should return false if the response was not successful" do
        expect(subject.save).to be false
      end
    end
  end

  describe "#save!" do
    before do
      stub_request(:put, "#{client_url}/a_resource").to_return( status: 412, headers: {}, body: "Bad If-Match header value: 'ae43aa934dc4f4e15ea1b4dd1ca7a56791972836'" )
    end

    it "should raise an exception if the ETag didn't match" do
      expect { subject.save! }.to raise_exception(Ldp::PreconditionFailed, "Bad If-Match header value: 'ae43aa934dc4f4e15ea1b4dd1ca7a56791972836'")
    end
  end

  describe "#value" do
    it "should provide a convenience method for retrieving values" do
      expect(subject.value(RDF::Vocab::DC.title).first.to_s).to eq "Hello, world!"
    end
  end

  describe "#reload" do
    let(:old_value) { subject.value(RDF::Vocab::DC.title).first.to_s }
    let(:updated_graph) { RDF::Graph.new << [RDF::URI.new(client_url), RDF::Vocab::DC.title, "Hello again, world!"] }

    before do
      old_value

      stub_request(:get, "#{client_url}/a_resource").to_return( status: 200, headers: {"Link" => ["<http://www.w3.org/ns/ldp#Resource>;rel=\"type\"", "<http://www.w3.org/ns/ldp#DirectContainer>;rel=\"type\""], "ETag" => "new-tag"}, body: updated_graph.dump(:ttl) )
    end

    it "loads the new values" do
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
