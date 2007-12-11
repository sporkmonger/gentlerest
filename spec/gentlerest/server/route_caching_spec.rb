lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "/../../../lib"))
spec_dir = File.expand_path(File.join(File.dirname(__FILE__), "/.."))
$:.unshift(lib_dir)
$:.unshift(spec_dir)

require "gentlerest"
require "gentlerest/http/client"
require "init_server"

class SpecController < GentleREST::BaseController
  action([:GET]) do
    response.plain_text
    response.body = "Hello world."
  end
end

describe GentleREST::Server, "when routing to '/{controller}/'" do
  before do
    @server = GentleREST.server(:default)
    @server.routes.clear
    @server.routes << GentleREST::Route.new(
      "/{controller}/", SpecController.new)
    @uri_prefix = "http://#{@server.address}:#{@server.port}"
  end
  
  it "should cache the result of routing a request" do
    response = GentleREST::HTTP.request(:GET, @uri_prefix + "/controller/")
    response.body.should == "Hello world."
    
    @server.cached_routes["/controller/"].should_not == nil
    @server.cached_routes["/controller/"].pattern.should == "/{controller}/"

    # A second request should function exactly as the first one did
    response = GentleREST::HTTP.request(:GET, @uri_prefix + "/controller/")
    response.body.should == "Hello world."
  end
  
  after do
    @server.routes.clear
  end
end
