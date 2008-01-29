#--
# GentleREST, Copyright (c) 2007 Bob Aman
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rubygems'
require 'mongrel'
require 'gentlerest/version'
require 'gentlerest/utilities/blank'
require 'gentlerest/server'
require 'gentlerest/server/http_request'
require 'gentlerest/server/http_response'
require 'gentlerest/server/http_cache'
require 'gentlerest/controllers/default_response_controller'
require 'gentlerest/controllers/redirect_controller'

module GentleREST
  # This is a specialized Mongrel http handler for GentleREST.
  class HttpHandler < Mongrel::HttpHandler
    def initialize(server)
      @server = server
      
      # Initialize the http cache.
      GentleREST::HttpCache.startup()
    end
    
    def server
      return @server
    end
    
    def process(mongrel_request, mongrel_response)
      if $PROFILE == true
        require 'ruby-prof'
        RubyProf.start
      end
      http_response = nil
      http_request = GentleREST::HttpRequest.new(mongrel_request)
      begin
        http_host = mongrel_request.params["HTTP_HOST"]
        http_uri = mongrel_request.params["REQUEST_URI"]

        # TODO: when X_FORWARDED_PROTO is set to "https", change the scheme
        uri = Addressable::URI.parse("http://#{http_host}#{http_uri}")
        
        http_response = GentleREST::HttpCache.retrieve(uri)
        if http_response == nil || ENV['GENTLE_ENV'] == 'development'
          method = mongrel_request.params["REQUEST_METHOD"]
          variables = nil
          selected_route = nil
          uri = Addressable::URI.parse(http_uri)
          cached_route = self.server.cached_routes[http_uri]
          if cached_route == nil
            for route in self.server.routes
              variables = uri.extract_mapping(route.pattern, route.processor)
              if variables != nil
                selected_route = route
                self.server.cached_routes[http_uri] = selected_route
                break
              end
            end
          else
            selected_route = cached_route
            variables = uri.extract_mapping(
              selected_route.pattern, selected_route.processor)
          end
          if selected_route != nil
            if selected_route.variables != nil
              # Merge variables given in route with those extracted
              # from the URI.
              variables = variables.merge(selected_route.variables)
            end
            http_request.variables = variables
            http_response = selected_route.controller.dispatch_action(
              http_request, GentleREST::HttpResponse.new)
          else
            # No route found.
            raise NoRouteError,
              "Unable to service request, no route found matching '#{uri}'."
          end
        end
      rescue Exception => error
        begin
          case error
          when GentleREST::NoRouteError,
              GentleREST::NoMatchingActionError,
              GentleREST::ResourceNotFoundError
            status = 404
          else
            status = 500
          end
          error_controller =
            GentleREST::DefaultResponseController.new(status, error)
          http_response = error_controller.dispatch_action(
            http_request, GentleREST::HttpResponse.new)
        rescue Exception => error
          puts "Exception raised while generating error page."
          puts "#{error.class.name}: #{error.message}"
          if error.respond_to?(:backtrace) && error.backtrace != nil
            puts error.backtrace.join("\n")
          else
            puts "Backtrace unavailable."
          end
        end
      end
      
      if http_response != nil
        if http_response.cache? && ENV['GENTLE_ENV'] != 'development'
          # This response should be cached.
          
          http_host = mongrel_request.params["HTTP_HOST"]
          http_uri = mongrel_request.params["REQUEST_URI"]

          # TODO: verify X_FORWARDED_PROTO works
          scheme = "http"
          if mongrel_request.params["HTTP_X_FORWARDED_PROTO"] != nil
            scheme = mongrel_request.params["HTTP_X_FORWARDED_PROTO"].downcase
          end
          
          uri = Addressable::URI.parse("#{scheme}://#{http_host}#{http_uri}")
          http_response.uri = uri
          
          GentleREST::HttpCache.cache(http_response)
        end
        
        # Copies the values over into the Mongrel response object.
        #
        # This is obviously not the most performant option, but the limitation
        # of having to set the headers before the content is set is somewhat
        # problematic.  Lesser of two evils and all that.
        mongrel_response.status = http_response.status
        http_response.headers = {
          "Server" => "GentleREST/#{GentleREST::Version::STRING}"
        }.merge(http_response.headers)
        for key, value in http_response.headers
          mongrel_response.header[key] = value
        end
        mongrel_response.body << (http_response.body || "")
      else
        mongrel_response.status = 500
        mongrel_response.body << "Fatal Error."
      end

      if $PROFILE == true
        result = RubyProf.stop
        if ENV["PROFILE_PRINTER"] == "html"
          printer = RubyProf::GraphHtmlPrinter.new(result)

          if ENV['GENTLE_ROOT'] != nil
            if !File.exists?(File.join(ENV['GENTLE_ROOT'], "/tmp"))
              Dir.mkdir(File.join(ENV['GENTLE_ROOT'], "/tmp"))
            end
            if !File.exists?(File.join(ENV['GENTLE_ROOT'], "/tmp/profile"))
              Dir.mkdir(File.join(ENV['GENTLE_ROOT'], "/tmp/profile"))
            end
            profile_dir =
              File.expand_path(File.join(ENV['GENTLE_ROOT'], "/tmp/profile"))
          else
            warn(
              "Could not find profile directory.  " +
              "Root directory was not set."
            )
            exit
          end

          output_filename = (Time.now.to_f * 10000).to_i.to_s + ".html"
          File.open(File.join(profile_dir, output_filename), "w") do |file|
            printer.print(file, 0)
          end
        else
          printer = RubyProf::FlatPrinter.new(result)
          printer.print(STDOUT, 0)
        end
      end
      return nil
    end
  end
end
