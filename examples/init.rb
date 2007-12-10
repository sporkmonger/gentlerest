# Load external start options
start_options = GentleREST.start_options(File.expand_path(__FILE__))

class HelloWorldController < GentleREST::BaseController
  action([:GET]) do
    response.plain_text
    response.body = "Hello world."
  end
end

class HomeController < GentleREST::BaseController
  action([:GET]) do
    response.html
    response.body = <<-HTML
<html>
  <head>
    <title>
      Root
    </title>
  </head>
  <body>
    This is the root path.
  </body>
</html>
HTML
  end

  action([:GET], "action" => "home") do
    response.plain_text
    response.body = "Welcome home."
  end
end

GentleREST.start(start_options) do |server|
  server.routes << GentleREST::Route.new("/hello/", HelloWorldController.new)
  server.routes << GentleREST::Route.new("/{action}/", HomeController.new)
  server.routes << GentleREST::Route.new("/", HomeController.new)
end
