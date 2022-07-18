require 'spec_helper'

describe Ldp::Resource do
  subject(:ldp_resource) { Ldp::Resource.new(mock_client, path) }

  before(:all) do
    WebMock.enable!
  end

  after(:all) do
    WebMock.disable!
  end

  before do
    stub_request(:post, "#{client_url}/foo").to_return(status: 201, headers: {
                                                         'Link': "#{client_url}/foo/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70/fcr:metadata>; rel=\"describedby\"; anchor=\"http://ldp.fcrepo4.lndo.site/rest/foo2/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70\"",
                                                         'Location': "#{client_url}/foo/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70"
                                                       })

    stub_request(:head, "#{client_url}/bad_request_resource").to_return(status: 400, headers: {})
    stub_request(:get, "#{client_url}/bad_request_resource").to_return(status: 400, headers: {}, body: "The namespace prefix (fooooooo) has not been registered")

    stub_request(:head, "#{client_url}/not_found_resource").to_return(status: 404, headers: {}, body: "The namespace prefix (fooooooo) has not been registered")
    stub_request(:get, "#{client_url}/not_found_resource").to_return(status: 404, headers: {}, body: "The namespace prefix (fooooooo) has not been registered")

    stub_request(:put, "#{client_url}/a_new_resource").to_return(status: 201, headers: {
                                                                   'Location': "#{client_url}/a_new_resource"
                                                                 })

    stub_request(:post, "#{client_url}/a_new_resource").to_return(status: 201, headers: {
                                                                    'Link': "#{client_url}/a_new_resource/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70/fcr:metadata>; rel=\"describedby\"; anchor=\"http://ldp.fcrepo4.lndo.site/rest/foo2/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70\"",
                                                                    'Location': "#{client_url}/a_new_resource/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70"
                                                                  })
    stub_request(:head, "#{client_url}/a_new_resource").to_return(status: 404, headers: {})

    stub_request(:get, "#{client_url}/a_resource").to_return(status: 200, headers: {})
    stub_request(:head, "#{client_url}/a_resource").to_return(status: 200, headers: {})
  end

  let(:client_url) do
    "http://my.ldp.server"
  end

  let(:http_client) do
    Faraday.new(url: client_url)
  end

  let :mock_client do
    Ldp::Client.new(http_client)
  end

  describe "#get" do
    context "when the resource is not in repository" do
      let(:path) { "/not_found_resource" }

      it "should raise an error" do
        expect { ldp_resource.get }.to raise_error Ldp::NotFound
      end
    end

    context "when the request is bad" do
      let(:path) { "/bad_request_resource" }
      it "should return a meaningful error message" do
        # Ensures that failed head requests rerun as a GET request in order to get a meaningful error message
        expect { ldp_resource.head }.to raise_error Ldp::BadRequest, "The namespace prefix (fooooooo) has not been registered"
      end
      it "should raise an error with error message" do
        expect { ldp_resource.get }.to raise_error Ldp::BadRequest, "The namespace prefix (fooooooo) has not been registered"
      end
    end

    context "when the resource is in the repository" do
      let(:path) { "/a_resource" }
      it "should get the response" do
        expect(ldp_resource.get).to be_kind_of Ldp::Response
      end
    end
  end

  describe "#new?" do
    context "with an object not in the repository" do
      let(:path) { "/not_found_resource" }
      it "should be true" do
        expect(ldp_resource).to be_new
      end
    end

    context "with an object in the repository" do
      let(:path) { "/a_resource" }
      it "should be false" do
        expect(ldp_resource).to_not be_new
      end
    end
  end

  describe "#head" do
    context "with an object not in the repository" do
      let(:path) { "/not_found_resource" }
      it "should be true" do
        expect(ldp_resource.head).to eq Ldp::None
      end

      it "should cache requests" do
        expect(ldp_resource.client).to receive(:head).and_raise(Ldp::NotFound).once
        2.times { ldp_resource.head }
      end
    end
  end

  describe "#create" do
    let(:path) { "/a_new_resource" }
    context "with a subject uri" do
      before do
        stub_request(:head, "#{client_url}#{path}").to_return(status: 404, headers: {})
        stub_request(:put, "#{client_url}#{path}").to_return(status: 201, headers: {
                                                               'Location': "#{client_url}#{path}"
                                                             })
      end

      context "and without a base path" do
        it "should post an RDF graph" do
          ldp_resource.content = "xyz"
          ldp_resource.save
        end
      end

      context "and with a base path" do
        let(:base_path) { "/foo" }

        before do
          stub_request(:head, "#{client_url}#{base_path}/a_new_resource").to_return(status: 404, headers: {})
          stub_request(:post, "#{client_url}#{base_path}/a_new_resource").to_return(status: 201, headers: {
                                                                                      'Link': "#{client_url}#{base_path}/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70/fcr:metadata>; rel=\"describedby\"; anchor=\"http://ldp.fcrepo4.lndo.site/rest/foo2/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70\"",
                                                                                      'Location': "#{client_url}#{base_path}/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70"
                                                                                    })
          stub_request(:put, "#{client_url}#{base_path}/a_new_resource").to_return(status: 201, headers: {
                                                                                     'Location': "#{client_url}/a_new_resource"
                                                                                   })
        end

        subject(:ldp_resource) { Ldp::Resource.new(mock_client, path, nil, base_path) }

        it "should ignore the base path" do
          ldp_resource.content = "xyz"
          ldp_resource.save
        end
      end
    end

    context "without a subject" do
      context "and with a base path" do
        let(:base_path) { "/foo" }

        before do
          stub_request(:post, "#{client_url}#{base_path}").to_return(status: 201, headers: {
                                                                       'Link': "#{client_url}#{base_path}/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70/fcr:metadata>; rel=\"describedby\"; anchor=\"http://ldp.fcrepo4.lndo.site/rest/foo2/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70\"",
                                                                       'Location': "#{client_url}#{base_path}/e7/ea/46/ea/e7ea46ea-cc8e-4cf4-86c3-99e04f130f70"
                                                                     })

          stub_request(:put, "#{client_url}#{base_path}").to_return(status: 201, headers: {
                                                                      'Location': "#{client_url}/a_new_resource"
                                                                    })
        end

        subject(:ldp_resource) { Ldp::Resource.new(mock_client, nil, nil, base_path) }

        it "should post an RDF graph" do
          ldp_resource.content = "xyz"
          ldp_resource.save
        end
      end
    end
  end

  describe "#update" do
    let(:path) { "/a_new_resource" }
    before do
      stub_request(:put, "#{client_url}#{path}").to_return(status: 201, headers: {
                                                             'Location': "#{client_url}/a_new_resource"
                                                           })
    end

    it "should pass headers" do
      ldp_resource.update do |req|
        req.headers = { "Content-Type" => "application/xml" }
      end
    end
  end
end
