require 'rubygems'
require 'gentlerest'
require 'applications/sporkblog'
require 'applications/sporkfed'

# Load external start options
start_options = GentleREST.start_options(File.expand_path(__FILE__))

GentleREST.start(start_options) do |server|
  Sporkblog.new(server, "/blog/")
  Sporkfed.new(server, "/fed/")
  server.routes.push(
    GentleREST::Route.new("/images/{path}",
      GentleREST::StaticFileController.new("static/images/{path}")),
    GentleREST::Route.new("/", HomeController.new)
  )
end
