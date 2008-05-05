lib_dir = File.expand_path(File.join(File.dirname(__FILE__), "/../../../lib"))
spec_dir = File.expand_path(File.join(File.dirname(__FILE__), "/.."))
$:.unshift(lib_dir)
$:.unshift(spec_dir)

require "gentlerest"
require "gentlerest/http/client"
require "gentlerest/extensions/robots"
require "init_server"

GOOGLEBOT_USER_AGENT =
  "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
GIGRIB_USER_AGENT =
  "Pingdom GIGRIB bot"

class RobotDetectionController < GentleREST::BaseController
  action([:GET]) do
    response.plain_text
    if request.robot?
      response.body = "You are a robot."
    else
      response.body = "You are not a robot."
    end
  end
end

describe GentleREST::Instance, "when routing to '/robot/'" do
  before do
    @instance = GentleREST.spec_instance
    @instance.routes.clear
    @instance.routes << GentleREST::Route.new(
      "/robot/", RobotDetectionController.new
    )
  end

  it "if a normal User-Agent is used it should not be detected" do
    response = GentleREST::HttpClient.request(
      :GET, GentleREST::AUTHORITY + "/robot/"
    )
    response.body.should == "You are not a robot."
  end

  it "if the Google User-Agent is used it should be detected" do
    response = GentleREST::HttpClient.request(
      :GET, GentleREST::AUTHORITY + "/robot/", {
        :request_headers => {
          "User-Agent" => GOOGLEBOT_USER_AGENT
        }
      }
    )
    response.body.should == "You are a robot."
  end

  it "if the GIGRIB User-Agent is used it should be detected" do
    response = GentleREST::HttpClient.request(
      :GET, GentleREST::AUTHORITY + "/robot/", {
        :request_headers => {
          "User-Agent" => GIGRIB_USER_AGENT
        }
      }
    )
    response.body.should == "You are a robot."
  end

  after do
    @instance.routes.clear
    @instance.cached_routes.clear
  end
end
