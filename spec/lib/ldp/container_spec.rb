require 'spec_helper'

describe Ldp::Container do
  subject(:container) { described_class.new(mock_client, path) }
  let(:client_url) do
    "http://my.ldp.server"
  end

  let(:http_client) do
    Faraday.new(url: client_url)
  end

  let(:client) do
    Ldp::Client.new(http_client)
  end

  before(:all) do
    WebMock.enable!
  end

  after(:all) do
    WebMock.disable!
  end

  let(:subject_uri) { "#{client_url}/foo" }
  let(:data) { instance_double(Ldp::Response) }

  before do
    stub_request(:post, "#{client_url}/foo").to_return(status: 201, headers: {
                                                         'Link': "#{client_url}/foo/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70/fcr:metadata>; rel=\"describedby\"; anchor=\"http://ldp.fcrepo4.lndo.site/rest/foo2/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70\"",
                                                         'Location': "#{client_url}/foo/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70"
                                                       })
  end

  describe ".for" do
    subject(:container) { described_class.for(client, subject_uri, data) }

    before do
      allow(data).to receive(:types).and_return(types)
    end

    context "when the data type is an Indirect Container" do
    let(:types) { [RDF::Vocab::LDP.IndirectContainer] }
      before do
        allow(data).to receive(:types).and_return(types)
      end
      it "constructs an Indirect Container" do
        expect(container).to be_an(Ldp::Container::Indirect)
      end
    end

    context "when the data type is an Indirect Container" do
    let(:types) { [RDF::Vocab::LDP.DirectContainer] }
      it "constructs an Direct Container" do
        expect(container).to be_an(Ldp::Container::Direct)
      end
    end
  end

end

