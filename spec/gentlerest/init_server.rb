require "gentlerest"
require "mongrel"
require "rack"
require "rack/handler/mongrel"

module GentleREST
  # This is the singleton instance used for running the specs.
  def self.spec_instance
    if !defined?(@spec_instance) || @spec_instance == nil
      @spec_instance = GentleREST.configure {}
    end
    return @spec_instance
  end
  
  if !defined?(@spec_server_running) || @spec_server_running == false
    @spec_server_running = true
    server = ::Mongrel::HttpServer.new('0.0.0.0', 4000)
    server.register('/',
      Rack::Handler::Mongrel.new(GentleREST.spec_instance.adapter))
    server.run
  end

  AUTHORITY = "http://127.0.0.1:4000"
end
