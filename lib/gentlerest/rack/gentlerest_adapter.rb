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

require "rubygems"
require "rack"
require "gentlerest/version"
require "gentlerest/utilities/blank"
require "gentlerest/instance"
require "gentlerest/http/request"
require "gentlerest/http/response"
require "gentlerest/cache/response_cache"
require "gentlerest/controllers/default_response_controller"
require "gentlerest/controllers/redirect_controller"

module Rack
  module Adapter
    # This is a GentleREST adapter for Rack.
    class GentleREST
      def initialize(instance)
        @instance = instance

        # Initialize the http cache.
        ::GentleREST::HttpResponseCache.startup()
      end
      
      def instance
        return @instance
      end
      
      def call(env)
        if $PROFILE == true
          require "ruby-prof"
          RubyProf.start
        end

        env["PATH_INFO"] ||= ""
        env["SCRIPT_NAME"] ||= ""

        http_response = nil
        http_request = ::GentleREST::HttpRequest.new(env)

        scheme = "http"
        if env["HTTP_X_FORWARDED_PROTO"] != nil
          scheme = env["HTTP_X_FORWARDED_PROTO"].downcase
        end

        host = env["HTTP_HOST"]
        if host == nil
          host = env["SERVER_NAME"] + ":" + env["SERVER_PORT"]
        end
        actual_uri = Addressable::URI.parse(
          "#{scheme}://#{host}" +
          env["SCRIPT_NAME"] + env["PATH_INFO"] + env["QUERY_STRING"]
        ).normalize

        begin
          http_response = ::GentleREST::HttpResponseCache.retrieve(actual_uri)
          if http_response == nil || ENV['ENVIRONMENT'] == 'development'
            method = env["REQUEST_METHOD"]
            variables = nil
            selected_route = nil
            cached_route = self.instance.cached_routes[http_request.uri.to_s]
            if cached_route == nil
              for route in self.instance.routes
                variables = http_request.uri.extract_mapping(
                  route.pattern, route.processor)
                if variables != nil
                  selected_route = route
                  self.instance.cached_routes[http_request.uri.to_s] =
                    selected_route
                  break
                end
              end
            else
              selected_route = cached_route
              variables = http_request.uri.extract_mapping(
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
                http_request, ::GentleREST::HttpResponse.new)
            else
              # No route found.
              raise NoRouteError,
                "Unable to service request, no route found matching " +
                "'#{http_request.uri.to_s}'."
            end
          end
        rescue Exception => error
          begin
            case error
            when ::GentleREST::NoRouteError,
                ::GentleREST::NoMatchingActionError,
                ::GentleREST::ResourceNotFoundError
              status = 404
            else
              status = 500
            end
            error_controller =
              ::GentleREST::DefaultResponseController.new(status, error)
            http_response = error_controller.dispatch_action(
              http_request, ::GentleREST::HttpResponse.new)
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

        if http_response == nil
          http_response = ::GentleREST::HttpResponse.new
          http_response.status = 500
          http_response.headers = {
            "Content-Type" => "text/plain"
          }
          http_response.body << "Fatal Error."
        end
        
        if http_response.cache? && ENV['ENVIRONMENT'] != 'development'
          # This response should be cached.
          ::GentleREST::HttpResponseCache.cache(actual_uri, http_response)
        end

        http_response.headers = {
          "Server" => "GentleREST/#{::GentleREST::Version::STRING}"
        }.merge(http_response.headers)
        http_response.body ||= ""

        if $PROFILE == true
          result = RubyProf.stop
          require "gentlerest/utilities/profile"
          ::GentleREST::ProfileWriter.write(result)
        end

        return [
          http_response.status, http_response.headers, http_response.body
        ]
      end
    end
  end
end
