class HelloWorldController < GentleREST::BaseController
  action([:GET]) do
    response.plain_text
    response.body = "Hello world."
  end
end

class HomeController < GentleREST::BaseController
  before do
    response.plain_text
    @start_time = Time.now
  end
  
  after do
    @render_time = Time.now - @start_time
  end
  
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
    response.cache = true
  end

  action([:GET], "action" => "home") do
    response.body = "Welcome home."
  end
end

GentleREST.start do |server|
  server.route(
    "/hello/", HelloWorldController.new, GentleREST::TrailingSlashBuilder)
  server.route(
    "/{action}/", HomeController.new, GentleREST::TrailingSlashBuilder)
  server.route(
    "/", HomeController.new)
end
