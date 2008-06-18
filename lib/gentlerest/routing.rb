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
require "addressable/uri"
require "gentlerest/errors"
require "gentlerest/instance"
require "gentlerest/processors/default_route_processor"
require "gentlerest/routing/builder"
require "gentlerest/routing/builders/trailing_slash_builder"

module GentleREST
  class Instance
    # Returns the list of all routes registered with an instance.
    def routes
      if !defined?(@routes) || @routes.blank?
        @routes = []
      end
      return @routes
    end
    
    # Returns a hash mapping uris to known routes.
    def cached_routes
      if !defined?(@cached_routes) || @cached_routes.blank?
        @cached_routes = {}
      end
      return @cached_routes
    end
    
    # Selects the first route that matches the given HTTP request.
    def select_route(uri)
      variables = nil
      selected_route = nil
      cached_route = self.cached_routes[uri.to_s]
      if cached_route == nil
        for route in self.routes
          variables = uri.extract_mapping(
            route.pattern, route.processor)
          if variables != nil
            selected_route = route
            self.cached_routes[uri.to_s] =
              selected_route
            break
          end
        end
      else
        selected_route = cached_route
      end
      return selected_route
    end
    
    # Returns the list of all defined route macros.
    def self.macros
      if !defined?(@macros) || @macros.blank?
        @macros = {}
      end
      return @macros
    end

    # Defines a macro for automating a set of route building parameters.
    # The method takes a suffix as a parameter.  After the macro has been
    # defined, the macro may be used by calling the appropriate
    # GentleREST::Instance#route_* method.
    def self.route_macro(suffix, pattern, options={})
      if !suffix.kind_of?(String) && !suffix.kind_of?(Symbol)
        raise TypeError,
          "Expected String or Symbol, got #{suffix.class.name}."
      end
      method = "route_#{suffix}".to_sym
      self.macros[method] = {
        :pattern => pattern,
        :options => options
      }
      method
    end
    
    # Creates one or more new routes with the given RouteBuilder.
    def route(pattern, options={})
      options[:builder] ||= GentleREST::RouteBuilder
      builder_class = options[:builder]
      begin
        builder = builder_class.new(pattern, options)
      rescue ArgumentError
        raise ArgumentError,
          "A RouteBuilder class must take a pattern and an " +
          "options Hash as parameters in its initialize method." 
      end
      if builder.respond_to?(:generate)
        new_routes = builder.generate
        new_routes.each do |route|
          if !route.kind_of?(GentleREST::Route)
            raise TypeError,
              "Expected GentleREST::Route, got #{route.class.name}."
          end
          self.routes << route
        end
        new_routes
      else
        raise TypeError,
          "An instantiated builder class must respond to the " +
          ":generate message."
      end
    end
    
    # Handles route macros which are defined at runtime.
    def method_missing(method, *params, &block)
      route_macro = self.class.macros[method]
      if route_macro.nil?
        super
      else
        pattern = params.shift || route_macro[:pattern]
        options = route_macro[:options].merge(params.shift || {})
        if !params.empty?
          raise ArgumentError,
            "wrong number of arguments (#{params.size + 2} for 2)"
        end
        route(pattern, options)
      end
    end
    
    # Returns true if the instance responds to the given method.
    def respond_to?(method, include_private=false)
      route_macro = self.class.macros[method]
      if route_macro.nil?
        super
      else
        true
      end
    end
  end
  
  # This class represents a route from a particular URI to the controller
  # that handles that URI.
  #
  # This method takes the following options:
  #
  # * :processor - A URI Template processor object.
  class Route
    def initialize(pattern, controller, options={})
      @pattern = pattern
      @controller = controller
      @options = options
      if @options[:processor] == nil
        # Use the default processor.
        @options[:processor] = GentleREST::DefaultRouteProcessor
      end
      if @options[:variables] == nil
        @options[:variables] = {}
      end
    end
    
    # Returns the URI Template pattern for the route.
    attr_reader :pattern
    
    # Sets the URI Template pattern for the route.
    attr_writer :pattern
    
    # Returns the controller object for the route.
    attr_reader :controller
    
    # Sets the controller object for the route.
    attr_writer :controller
    
    # Returns the URI Template processor object.
    def processor
      return @options[:processor]
    end
    
    # Sets the URI Template processor object.
    def processor=(new_processor)
      @options[:processor] = new_processor
    end
    
    def deferred?
      return (!!@options[:deferred])
    end

    def deferred=(new_deferred)
      @options[:deferred] = (!!new_deferred)
    end

    # Returns the variables that were specified for this route.
    def variables
      return @options[:variables]
    end

    # Inspects the internal state of the route.
    def inspect
      return "#<GentleREST::Route:0x#{self.object_id.to_s(16)} " +
        "PATTERN:#{self.pattern.inspect} " +
        "CONTROLLER:#{self.controller.class.to_s}>"
    end
  end
end
