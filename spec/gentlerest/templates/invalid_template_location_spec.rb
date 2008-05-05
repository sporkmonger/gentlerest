lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "/../../../lib"))
spec_dir = File.expand_path(File.join(File.dirname(__FILE__), "/.."))
$:.unshift(lib_dir)
$:.unshift(spec_dir)

require "gentlerest"
require "gentlerest/http/client"
require "init_server"

spec_data_dir = File.expand_path(
  File.join(File.dirname(__FILE__), "../../data"))
spec_template_dir = File.join(spec_data_dir, "templates")
spec_insecure_dir = File.join(spec_data_dir, "insecure")
$TEMPLATE_PATH << spec_template_dir

class InvalidTemplateLocationController < GentleREST::BaseController
  action([:GET]) do
    response.xhtml
    response.render "../insecure/insecure.haml"
  end
end

describe GentleREST::Instance, "when routing to '/{path}/'" do
  before do
    @instance = GentleREST.spec_instance
    @instance.routes.clear
    @instance.routes << GentleREST::Route.new(
      "/{path}/", InvalidTemplateLocationController.new
    )
  end
  
  it "should not allow rendering of an insecure template" do
    response = GentleREST::HttpClient.request(
      :GET, GentleREST::AUTHORITY + "/controller/")
    response.body.strip.should_not == "This file should never be rendered."
    response.status.should == 404
  end
  
  after do
    @instance.routes.clear
    @instance.cached_routes.clear
  end
end
