require 'spec_helper'

describe Ldp::Resource, lamprey_server: true do
  subject(:resource) { described_class.new(client, subject_uri) }

  let(:conn_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.head('/bad_request_resource') { [400] } # HEAD requests do not have message bodies.
      stub.head('/not_found_resource') { [404] }
      stub.head('/a_new_resource') { [404] }
      stub.head('/a_resource') { [200] }

      stub.get('/bad_request_resource') { [400, {}, "The namespace prefix (fooooooo) has not been registered"] }
      stub.get('/not_found_resource') { [404] }
      stub.get('/a_resource') { [200] }
    end
  end

  let(:client) { @client }
  let(:subject_uri) { '/resource' }

  describe "#get" do
    let(:subject_uri) { '/resource0' }

    context "when the resource is not in repository" do
      before do
        resource.delete
      end

      it "raises an error" do
        expect { resource.get }.to raise_error(Ldp::NotFound)
      end
    end

    context "when the request is bad" do
      #let(:subject_uri) { '/bad_request_resource' }
      let(:get_response) { instance_double(Faraday::Response) }
      let(:head_response) { instance_double(Faraday::Response) }
      let(:request) { instance_double(Faraday::Request) }
      let(:head_env) { instance_double(Faraday::Env) }
      let(:get_env) { instance_double(Faraday::Env) }
      let(:url) { instance_double(URI::HTTP) }

      before do
        allow(url).to receive(:path).and_return(subject_uri)
        allow(head_env).to receive(:url).and_return(url)
        allow(head_env).to receive(:method).and_return(:head)
        allow(head_response).to receive(:env).and_return(head_env)
        allow(head_response).to receive(:status).and_return(400)

        allow(get_env).to receive(:method).and_return(:get)
        allow(get_response).to receive(:env).and_return(get_env)
        allow(get_response).to receive(:status).and_return(400)
        allow(get_response).to receive(:body).and_return("The namespace prefix (fooooooo) has not been registered")

        allow_any_instance_of(Faraday::Connection).to receive(:head).and_return(head_response)
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(get_response)
      end

      it "returns a meaningful error message" do
        # Ensures that failed head requests rerun as a GET request in order to get a meaningful error message
        expect { resource.head }.to raise_error Ldp::BadRequest, "The namespace prefix (fooooooo) has not been registered"
      end

      it "raises an error with error message" do
        resource.create
        expect { resource.get }.to raise_error Ldp::BadRequest, "The namespace prefix (fooooooo) has not been registered"
      end
    end

    context "when the resource is in the repository" do
      subject(:resource) { described_class.new(client, subject_uri) }

      before do
        resource.create
      end
      after do
        resource.delete
      end

      xit "gets the response" do
        expect(resource.get).to be_kind_of(Ldp::Response)
      end
    end
  end

  describe "#new?" do
    let(:subject_uri) { '/resource1' }

    context "with an object not in the repository" do
      before do
        resource.delete
      end

      it "returns true" do
        expect(resource).to be_new
      end
    end

    context "with an object in the repository" do

      before do
        resource.create
      end

      it "returns false" do
        expect(resource).not_to be_new
      end
    end
  end

  describe "#head" do
    let(:subject_uri) { '/resource2' }

    context "with an object not in the repository" do

      before do
        resource.delete
      end

      xit "returns Ldp::None" do
        expect(resource.head).to eq(Ldp::None)
      end

      xit "caches requests" do
        expect(resource.client).to receive(:head).and_raise(Ldp::NotFound).once
        2.times { resource.head }

        expect(resource.client).to have_received(:head).and_raise(Ldp::NotFound).once
      end
    end
  end

  describe "#create" do
    let(:subject_uri) { '/resource3' }

    before do
      resource.delete
    end

    context "with a subject uri" do
      let(:conn_stubs) do
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.head(subject_uri) { [404] }
          stub.put(subject_uri) { [200, { 'Last-Modified' => 'Tue, 22 Jul 2014 02:23:32 GMT' }] }
        end
      end

      context "and without a base path" do
        subject(:resource) { described_class.new(client, subject_uri, nil, nil) }

        it "posts an RDF graph" do
          #resource.content = "xyz"
          resource.create
        end
      end

      context "and with a base path" do
        subject(:resource) { described_class.new(client, subject_uri, nil, base_path) }
        let(:base_path) { '/foo' }

        it "ignores the base path" do
          #resource.content = "xyz"
          resource.create
        end
      end
    end

    context "without a subject" do
      context "and with a base path" do
        subject(:resource) { described_class.new(client, nil, nil, base_path) }
        let(:base_path) { '/foo' }

        let(:conn_stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post(base_path) { [200, { 'Last-Modified' => 'Tue, 22 Jul 2014 02:23:32 GMT' }] }
          end
        end

        it "posts an RDF graph" do
          # resource.content = "xyz"
          resource.create
        end
      end
    end
  end

  describe "#update" do
    let(:subject_uri) { '/resource4' }

    before do
      resource.create

      resource.update do |req|
        req.headers = { 'Content-Type' => 'application/xml' }
      end
    end

    xit "passes headers" do
      resource.content = "xyz"
      resource.update
    end
  end
end
