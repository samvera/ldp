require 'spec_helper'

describe Ldp::Orm do
  subject { Ldp::Orm.new test_resource }
  
  let(:simple_graph) do
    graph = RDF::Graph.new << [RDF::URI.new(""), RDF::DC.title, "Hello, world!"]
    graph.dump(:ttl)
  end

  let(:conn_stubs) do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get('/a_resource') {[ 200, {"Link" => "http://www.w3.org/ns/ldp#Resource;rel=\"type\""}, simple_graph ]}
      stub.put("/a_resource") { [204]}
    end
  end

  let(:mock_conn) do
    test = Faraday.new do |builder|
      builder.adapter :test, conn_stubs do |stub|
      end
    end
  end

  let :mock_client do
    Ldp::Client.new mock_conn
  end

  let :test_resource do
    Ldp::Resource.new mock_client, "http://example.com/a_resource"
  end

  describe "#delete" do
    it "should delete the LDP resource" do
      test_resource.should_receive(:delete)
      subject.delete
    end
  end

  describe "#create" do

  end

  describe "#save" do
    it "should update the resource from the graph" do
      expect(subject.save).to be_true
    end

    it "should provide a graph of differences if the post-save graph doesn't match our graph" do
      subject.graph << RDF::Statement.new(:subject => subject.resource.subject_uri, :predicate => RDF::URI.new("info:some-predicate"), :object => RDF::Literal.new("xyz"))
      result = subject.save
      expect(result).to_not be_empty
    end
  end

  describe "#save!" do
    it "should raise an exception if there are differences after saving the graph" do
      subject.graph << RDF::Statement.new(:subject => subject.resource.subject_uri, :predicate => RDF::URI.new("info:some-predicate"), :object => RDF::Literal.new("xyz"))
      expect { subject.save! }.to raise_exception
    end
  end

  describe "#value" do
    it "should provide a convenience method for retrieving values" do
      expect(subject.value(RDF::DC.title).first.to_s).to eq "Hello, world!"
    end
  end
end