require 'spec_helper'
describe "Ldp::Client" do

    let(:simple_graph) do
      graph = RDF::Graph.new << [RDF::URI.new(""), RDF::DC.title, "Hello, world!"]
      graph.dump(:ttl)
    end


    let(:paginatedGraph) do
      graph = RDF::Graph.new << [RDF::URI.new(""), RDF::DC.title, "Hello, world!"]
      graph << [RDF::URI.new("?firstPage"), RDF.type, Ldp.page]
      graph << [RDF::URI.new("?firstPage"), Ldp.page_of, RDF::URI.new("")]
      graph.dump(:ttl)
    end

    let(:simple_container_graph) do
      graph = RDF::Graph.new << [RDF::URI.new(""), RDF.type, Ldp.container]
      graph.dump(:ttl)
    end

    let(:conn_stubs) do
      stubs = Faraday::Adapter::Test::Stubs.new do |stub|
        stub.get('/a_resource') {[ 200, {"Link" => "http://www.w3.org/ns/ldp#Resource;rel=\"type\""}, simple_graph ]}
        stub.get('/a_container') {[ 200, {"Link" => "http://www.w3.org/ns/ldp#Resource;rel=\"type\""}, simple_container_graph ]}
        stub.put("/a_resource") { [204]}
        stub.delete("/a_resource") { [204]}
        stub.post("/a_container") { [201, {"Location" => "http://example.com/a_container/subresource"}]}
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

    it "should accept a block to change the HTTP request" do
      expect { |b| subject.get "a_resource", &b }.to yield_control
    end
  end

  describe "delete" do
    it "should DELETE the subject from the HTTP endpoint" do
      resp = subject.delete "a_resource"
      expect(resp.status).to eq(204)
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| subject.delete "a_resource", &b }.to yield_control
    end
  end

  describe "post" do

    it "should POST to the subject at the HTTP endpoint" do
      resp = subject.post "a_container"
      expect(resp.status).to eq(201)
      expect(resp.headers[:Location]).to eq("http://example.com/a_container/subresource")
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| subject.post "a_container", &b }.to yield_control
    end

  end

  describe "put" do
    it "should PUT content to the subject at the HTTP endpoint" do
      resp = subject.put "a_resource", "some-payload"
      expect(resp.status).to eq(204)
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| subject.put "a_resource", "some-payload", &b }.to yield_control
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