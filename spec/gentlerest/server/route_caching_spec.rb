lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "/../../../lib"))
spec_dir = File.expand_path(File.join(File.dirname(__FILE__), "/.."))
$:.unshift(lib_dir)
$:.unshift(spec_dir)

require "gentlerest"
require "gentlerest/http/client"
require "init_server"

class RouteCachingController < GentleREST::BaseController
  action([:GET]) do
    response.plain_text
    response.body = "Hello world."
  end
end

describe GentleREST::Instance, "when routing to '/{controller}/'" do
  before do
    @instance = GentleREST.spec_instance
    @instance.routes.clear
    @instance.routes << GentleREST::Route.new(
      "/{controller}/", RouteCachingController.new
    )
  end
  
  it "should cache the result of routing a request" do
    response = GentleREST::HttpClient.request(
      :GET, GentleREST::AUTHORITY + "/controller/")
    response.body.should == "Hello world."
    
    @instance.cached_routes["/controller/"].should_not == nil
    @instance.cached_routes["/controller/"].pattern.should == "/{controller}/"

    # A second request should function exactly as the first one did
    response = GentleREST::HttpClient.request(
      :GET, GentleREST::AUTHORITY + "/controller/")
    response.body.should == "Hello world."
  end
  
  after do
    @instance.routes.clear
    @instance.cached_routes.clear
  end
end
