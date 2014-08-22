require 'spec_helper'

describe Ldp::Resource::RdfSource do
  let(:simple_graph) do
    RDF::Graph.new << [RDF::URI.new(), RDF::DC.title, "Hello, world!"]
  end

  let(:conn_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.post("/") { [201]}
      stub.put("/abs_url_object") { [201]}
    end
  end

  let(:mock_conn) do
    Faraday.new url: "http://my.ldp.server/" do |builder|
      builder.adapter :test, conn_stubs do |stub|
      end
    end
  end

  let :mock_client do
    Ldp::Client.new mock_conn
  end


  describe "#create" do
    subject { Ldp::Resource::RdfSource.new mock_client, nil }

    it "should return a new resource" do
      created_resource = subject.create
      expect(created_resource).to be_kind_of Ldp::Resource::RdfSource
    end

    it "should allow absolute URLs to the LDP server" do
      obj = Ldp::Resource::RdfSource.new mock_client, "http://my.ldp.server/abs_url_object"
      allow(obj).to receive(:new?).and_return(true)
      created_resource = obj.create
      expect(created_resource).to be_kind_of Ldp::Resource::RdfSource
    end
  end

  describe "#initialize" do
    context "with bad attributes" do
      it "should raise an error" do
        expect{ Ldp::Resource::RdfSource.new mock_client, nil, "derp" }.to raise_error(ArgumentError,
          "Third argument to Ldp::Resource::RdfSource.new should be a RDF::Graph or a Ldp::Response. You provided String")
      end
    end
  end

  context "When graph_class is overridden" do
    before do
      class SpecialGraph < RDF::Graph; end

      class SpecialResource < Ldp::Resource::RdfSource
        def graph_class
          SpecialGraph
        end
      end
    end

    after do
      Object.send(:remove_const, :SpecialGraph)
      Object.send(:remove_const, :SpecialResource)
    end

    subject { SpecialResource.new mock_client, nil }

    it "should use the specified class" do
      expect(subject.graph).to be_a SpecialGraph
    end
  end
end
