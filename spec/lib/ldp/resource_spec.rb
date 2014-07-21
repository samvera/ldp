require 'spec_helper'

describe Ldp::Resource do
  subject { Ldp::Resource.new(mock_client, path) }

  let(:conn_stubs) do
    stubs = Faraday::Adapter::Test::Stubs.new do |stub|
      stub.head('/not_found_resource') { [404] }
      stub.get('/not_found_resource') { [404] }
      stub.head('/a_new_resource') { [404] }
      stub.head('/a_resource') { [200] }
      stub.get('/a_resource') { [200] }
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

  describe "#get" do
    context "when the resource is not in repository" do
      let(:path) { '/not_found_resource' }
      it "should raise an error" do
        expect{ subject.get }.to raise_error Ldp::NotFound
      end
    end

    context "when the resource is in the repository" do
      let(:path) { '/a_resource' }
      it "should get the response" do
        expect(subject.get).to be_kind_of Faraday::Response
        expect(subject.get.status).to eq 200
      end
    end
  end
  
  describe "#new?" do
    context "with an object not in the repository" do
      let(:path) { '/not_found_resource' }
      it "should be true" do  
        expect(subject).to be_new
      end
    end
    
    context "with an object in the repository" do
      let(:path) { '/a_resource' }
      it "should be false" do  
        expect(subject).to_not be_new
      end
    end
  end
  
  describe "#create" do
    let(:path) { '/a_new_resource' }
    context "with initial content" do
      it "should post an RDF graph" do
        expect(mock_client).to receive(:put).with(path, "xyz").and_return(double(headers: {}))
        subject.content = "xyz"
        subject.save
      end
    end
    context "with a base path content (create a subresource)" do
      let(:base_path) { '/foo' }
      context "Of the root" do
        subject { Ldp::Resource.new(mock_client, nil, nil, base_path) }
        it "should post an RDF graph" do
          expect(mock_client).to receive(:post).with(base_path, "xyz").and_return(double(headers: {}))
          subject.content = "xyz"
          subject.save
        end
      end
      context "of some other element" do
        subject { Ldp::Resource.new(mock_client, path, nil, base_path) }
        it "should ignore the base path" do
          expect(mock_client).to receive(:put).with(path, "xyz").and_return(double(headers: {}))
          subject.content = "xyz"
          subject.save
        end
      end
    end
  end
end
