require 'spec_helper'
describe "Ldp::Client" do

    let(:simple_graph) do
      graph = RDF::Graph.new << [RDF::URI.new(""), RDF::DC.title, "Hello, world!"]
      graph.dump(:ttl)
    end

    let(:simple_container_graph) do
      graph = RDF::Graph.new << [RDF::URI.new(""), RDF.type, Ldp.container]
      graph.dump(:ttl)
    end

    let(:conn_stubs) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/a_resource') {[ 200, {"Link" => "http://www.w3.org/ns/ldp/Resource;rel=\"type\""}, simple_graph ]}
        stub.get('/a_container') {[ 200, {"Link" => "http://www.w3.org/ns/ldp/Resource;rel=\"type\""}, simple_container_graph ]}
      
      end
    end

    let(:mock_conn) do
      test = Faraday.new do |builder|
        builder.adapter :test, conn_stubs do |stub|
        end
      end

    end

    subject do
      Ldp::Client.new mock_conn
    end

  describe "initialize" do
    it "should accept an existing Faraday connection" do
      conn = Faraday.new "http://example.com"
      client = Ldp::Client.new conn
      expect(client.http).to eq(conn)
    end

    it "should create a connection from Faraday constructor params" do
      client = Ldp::Client.new "http://example.com"
      expect(client.http.host).to eq("example.com")
    end
  end

  describe "get" do

    it "should GET content from the HTTP endpoint" do
      resp = subject.get "a_resource"
      expect(resp).to be_a_kind_of(Ldp::Response)
      expect(resp.body).to eq(simple_graph)
      expect(resp.resource?).to be_true
    end

    describe "response" do

    end
  end

  describe "find_or_initialize" do
    it "should be a resource" do
      resource = subject.find_or_initialize "a_resource"
      expect(resource).to be_a_kind_of(Ldp::Resource)
    end

    it "should be a container" do
      resource = subject.find_or_initialize "a_container"
      expect(resource).to be_a_kind_of(Ldp::Resource)
      expect(resource).to be_a_kind_of(Ldp::Container)
    end

  end
end