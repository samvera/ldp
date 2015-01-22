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
      stub.put("/conflict_resource") { [409, {}, ''] }
      stub.get("/deleted_resource") { [410, {}, 'Gone'] }
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
      expect(resp.resource?).to be true
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| subject.get "a_resource", &b }.to yield_control
    end

    context "should provide convenient accessors for LDP Prefer headers" do
      it "should set the minimal header" do
        subject.get "a_resource", minimal: true do |req|
          expect(req.headers["Prefer"]).to eq "return=minimal"
        end
      end
      it "should set the include parameter" do
        subject.get "a_resource", include: "membership" do |req|
          expect(req.headers["Prefer"]).to match "include=\"#{Ldp.prefer_membership}\""
        end
      end
      it "should set the omit parameter" do
        subject.get "a_resource", omit: "containment" do |req|
          expect(req.headers["Prefer"]).to match "omit=\"#{Ldp.prefer_containment}\""
        end
      end
    end

    context "with an invalid relative uri" do
      it "should work" do
        subject.get "test:1"
      end
    end

    context "with an absolute uri" do
      it "should work" do
        subject.get "http://test:8080/abc"
      end
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

    it "should set content" do
      subject.post "a_container", 'foo' do |req|
        expect(req.body).to eq 'foo'
      end
    end

    it "should set default Content-type" do
      subject.post "a_container", 'foo' do |req|
        expect(req.headers).to include({ "Content-Type" => "text/turtle" })
      end
    end

    it "should set headers" do
      subject.post "a_container", 'foo', {'Content-Type' => 'application/pdf'} do |req|
        expect(req.headers).to include({ "Content-Type" => "application/pdf" })
      end
    end

    it "should set headers passed as arguments" do
      resp = subject.post "a_container"
    end

    it "should accept a block to change the HTTP request" do
      expect { |b| subject.post "a_container", &b }.to yield_control
    end

    it "should preserve basic auth headers" do
      subject.http.basic_auth('Aladdin', 'open sesame')
      subject.post "a_container", 'foo' do |req|
        expect(req.headers).to include({ "Authorization" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" })
      end
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

    it "should set headers" do
      subject.put "a_resource", 'payload', {'Content-Type' => 'application/pdf'} do |req|
        expect(req.headers).to include({ "Content-Type" => "application/pdf" })
      end
    end

    describe "error checking" do
      it "should check for 409 errors" do
        expect { subject.put "conflict_resource", "some-payload" }.to raise_error Ldp::HttpError
      end

      it "should check for 410 errors" do
        expect { subject.get "deleted_resource" }.to raise_error Ldp::Gone
      end

      it "should check for 412 errors" do
        expect { subject.put "mismatch_resource", "some-payload" }.to raise_error Ldp::EtagMismatch
      end
    end

    it "should preserve basic auth headers" do
      subject.http.basic_auth('Aladdin', 'open sesame')
      subject.put "a_resource", "some-payload" do |req|
        expect(req.headers).to include({ "Authorization" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" })
      end
    end

  end

  describe 'patch' do

    it "should preserve basic auth headers" do
      subject.http.basic_auth('Aladdin', 'open sesame')
      subject.patch "a_container", 'foo' do |req|
        expect(req.headers).to include({ "Authorization" => "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==" })
      end
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

    it "should be a binary resource" do
      resource = subject.find_or_initialize "a_binary_resource"
      expect(resource).to be_a_kind_of(Ldp::Resource::BinarySource)
    end

  end
end
