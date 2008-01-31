require "rubygems"
require "gentlerest"
require "applications/sporkblog"
require "applications/sporkfed"

GentleREST.start do |server|
  Sporkblog.new(server, "/blog/")
  Sporkfed.new(server, "/fed/")
  server.routes.push(
    GentleREST::Route.new("/images/{path}",
      GentleREST::StaticFileController.new("static/images/{path}")),
    GentleREST::Route.new("/", HomeController.new)
  )
end
