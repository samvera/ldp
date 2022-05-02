require 'spec_helper'
require 'rdf/vocab'

describe Ldp::Client, lamprey_server: true do
  subject(:client) { described_class.new(connection, options) }

  let(:server) { @server }

  let(:simple_graph_resource) do
    RDF::Graph.new << [RDF::URI.new(""), RDF::Vocab::DC.title, "Hello, world!"]
  end

  let(:simple_graph) do
    simple_graph_resource.dump(:ttl)
  end

  let(:simple_container_graph_resource) do
    RDF::Graph.new << [RDF::URI.new(""), RDF.type, RDF::Vocab::LDP.Container]
  end

  let(:simple_container_graph) do
    simple_container_graph_resource.dump(:ttl)
  end

  let(:connection_stubs) do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.head('/a_resource') { [200] }
      stub.get('/a_resource') { [200, {"Link" => "<http://www.w3.org/ns/ldp#Resource>;rel=\"type\""}, simple_graph] }
      stub.get('/a_container') { [200, {"Link" => ["<http://www.w3.org/ns/ldp#Resource>;rel=\"type\"","<http://www.w3.org/ns/ldp#BasicContainer>;rel=\"type\""]}, simple_container_graph] }
      stub.head('/a_binary_resource') { [200] }
      stub.get('/a_binary_resource') { [200, {}, ""] }
      stub.put("/a_resource") { [204]}
      stub.delete("/a_resource") { [204] }
      stub.head('/a_container') { [200] }
      stub.post("/a_container") { [201, {"Location" => "http://example.com/a_container/subresource"}] }
      stub.patch("/a_container") { [201, {"Location" => "http://example.com/a_container/subresource"}] }
      stub.get("/test:1") { [200] }
      stub.get("http://test:8080/abc") { [200] }
      stub.put("/mismatch_resource") { [412] }
      stub.put("/forbidden_resource") { [403, {}, ''] }
      stub.put("/conflict_resource") { [409, {}, ''] }
      stub.get("/deleted_resource") { [410, {}, 'Gone'] }
      stub.head("/temporary_redirect1") { [302, {"Location" => "http://example.com/new"}] }
      stub.head("/temporary_redirect2") { [307, {"Location" => "http://example.com/new"}] }
      stub.head("/permanent_redirect1") { [301, {"Location" => "http://example.com/new"}] }
      stub.head("/permanent_redirect2") { [308, {"Location" => "http://example.com/new"}] }
    end
  end

  let(:connection) do
    @connection
  end

  let(:options) do
    {}
  end

  describe ".new" do
    let(:connection) { Faraday.new("http://example.com") }

    it "should accept an existing Faraday connection" do
      expect(client.http).to eq(connection)
    end

    it "should create a connection from Faraday constructor params" do
      expect(client.http.host).to eq("example.com")
    end

    context 'with additional client options' do
      let(:options) do
        {
          omit_ldpr_interaction_model: true
        }
      end

      it 'passes client options to the underlying HTTP client' do
        expect(client.http).to eq(connection)
        expect(client.options[:omit_ldpr_interaction_model]).to eq true
      end
    end

    context 'when passing invalid constructor arguments' do
      subject(:client) { described_class(nil, nil, nil) }

      it 'raises an ArgumentError' do
        expect { client }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#logger' do
    it 'inherits the upstream logger' do
      expect(client.logger).to eq Ldp.logger
    end

    xit "is instrumented" do
      vals = []
      ActiveSupport::Notifications.subscribe('http.ldp') do |name, start, finish, id, payload|
        vals << payload[:name]
      end
      client.get "a_resource"
      expect(vals).to eq ['GET']
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| client.get "a_resource", &b }.to yield_control
    end

    context "should provide convenient accessors for LDP Prefer headers" do
      let(:subject_uri) { '/a_resource' }
      let(:base_path) { '' }
      let(:resource) { Ldp::Resource.new(client, subject_uri, nil, base_path) }

      before do
        resource.save
      end

      it "should set the minimal header" do
        client.get subject_uri, minimal: true do |req|
          expect(req.headers["Prefer"]).to eq "return=minimal"
        end
      end

      it "should set the include parameter" do
        client.get subject_uri, include: "membership" do |req|
          expect(req.headers["Prefer"]).to match "include=\"#{RDF::Vocab::LDP.PreferMembership}\""
        end
      end

      it "should set the omit parameter" do
        client.get subject_uri, omit: "containment" do |req|
          expect(req.headers["Prefer"]).to match "omit=\"#{RDF::Vocab::LDP.PreferContainment}\""
        end
      end
    end

    context "with an invalid relative uri" do
      let(:subject_uri) { '/test:1' }
      let(:resource) { Ldp::Resource.new(client, subject_uri, nil, nil) }

      before do
        resource.save
      end

      it "should work" do
        client.get("test:1")
      end
    end

    context "with an absolute uri" do
      let(:subject_uri) { '/abc' }
      let(:resource) { Ldp::Resource.new(client, subject_uri, nil, nil) }

      before do
        resource.save
      end

      it "should work" do
        client.get("#{server.url}/abc")
      end
    end
  end

  describe "delete" do
    let(:subject_uri) { '/deleted_resource' }
    let(:resource) { Ldp::Resource.new(client, subject_uri, nil, base_path) }

    it "should DELETE the subject from the HTTP endpoint" do
      resp = client.delete "a_resource"
      expect(resp.status).to eq(204)
    end

    it "is instrumented" do
      vals = []
      ActiveSupport::Notifications.subscribe('http.ldp') do |name, start, finish, id, payload|
        vals << payload[:name]
      end
      client.delete "a_resource"
      expect(vals).to eq ['DELETE']
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| client.delete "a_resource", &b }.to yield_control
    end
  end

  describe "post" do
    it "should POST to the subject at the HTTP endpoint" do
      resp = client.post "a_container"
      expect(resp.status).to eq(201)
      expect(resp.headers[:Location]).to eq("http://example.com/a_container/subresource")
    end

    it "is instrumented" do
      vals = []
      ActiveSupport::Notifications.subscribe('http.ldp') do |name, start, finish, id, payload|
        vals << payload[:name]
      end
      client.post "a_container"
      expect(vals).to eq ['POST']
    end

    it "should set content" do
      client.post "a_container", 'foo' do |req|
        expect(req.body).to eq 'foo'
      end
    end

    it "should set default Content-type" do
      client.post "a_container", 'foo' do |req|
        expect(req.headers).to include({ "Content-Type" => "text/turtle" })
      end
    end

    it "should set headers" do
      client.post "a_container", 'foo', {'Content-Type' => 'application/pdf'} do |req|
        expect(req.headers).to include({ "Content-Type" => "application/pdf" })
      end
    end

    it "should set headers passed as arguments" do
      resp = client.post "a_container"
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| client.post "a_container", &b }.to yield_control
    end

    it "should preserve basic auth headers" do
      client.http.basic_auth('Aladdin', 'open sesame')
      client.post "a_container", 'foo' do |req|
        expect(req.headers).to include({ "Authorization" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" })
      end
    end

  end

  describe "put" do
    it "should PUT content to the subject at the HTTP endpoint" do
      resp = client.put "a_resource", "some-payload"
      expect(resp.status).to eq(204)
    end

    it "is instrumented" do
      vals = []
      ActiveSupport::Notifications.subscribe('http.ldp') do |name, start, finish, id, payload|
        vals << payload[:name]
      end
      client.put "a_resource", "some-payload"
      expect(vals).to eq ['PUT']
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| client.put "a_resource", "some-payload", &b }.to yield_control
    end

    it "should set headers" do
      client.put "a_resource", 'payload', {'Content-Type' => 'application/pdf'} do |req|
        expect(req.headers).to include({ "Content-Type" => "application/pdf" })
      end
    end

    describe "error checking" do
      it "checks for other kinds of 4xx errors" do
        expect { client.put "forbidden_resource", "some-payload" }.to raise_error Ldp::HttpError
      end

      it "checks for 409 errors" do
        expect { client.put "conflict_resource", "some-payload" }.to raise_error Ldp::Conflict
      end

      it "checks for 410 errors" do
        expect { client.get "deleted_resource" }.to raise_error Ldp::Gone
      end

      it "checks for 412 errors" do
        expect { client.put "mismatch_resource", "some-payload" }.to raise_error Ldp::PreconditionFailed
      end
    end

    it "should preserve basic auth headers" do
      client.http.basic_auth('Aladdin', 'open sesame')
      client.put "a_resource", "some-payload" do |req|
        expect(req.headers).to include({ "Authorization" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" })
      end
    end

  end

  describe 'patch' do

    it "should preserve basic auth headers" do
      client.http.basic_auth('Aladdin', 'open sesame')
      client.patch "a_container", 'foo' do |req|
        expect(req.headers).to include({ "Authorization" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" })
      end
    end

  end

  describe "find_or_initialize" do
    it "should be a resource" do
      resource = client.find_or_initialize "a_resource"
      expect(resource).to be_a_kind_of(Ldp::Resource)
    end

    it "should be a container" do
      resource = client.find_or_initialize "a_container"
      expect(resource).to be_a_kind_of(Ldp::Resource)
      expect(resource).to be_a_kind_of(Ldp::Container)
    end

    it "should be a binary resource" do
      resource = client.find_or_initialize "a_binary_resource"
      expect(resource).to be_a_kind_of(Ldp::Resource::BinarySource)
    end
  end

  describe "head" do
    it "treats temporary redirects as successful" do
      expect { client.head "temporary_redirect1" }.not_to raise_error
      expect { client.head "temporary_redirect2" }.not_to raise_error
    end

    it "treats permanent redirects as successful" do
      expect { client.head "permanent_redirect1" }.not_to raise_error
      expect { client.head "permanent_redirect2" }.not_to raise_error
    end
  end
end
