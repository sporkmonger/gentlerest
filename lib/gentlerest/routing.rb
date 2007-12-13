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
require 'addressable/uri'
require 'gentlerest/errors'

module GentleREST
  class Server
    # Returns the list of all routes registered with a server.
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
  end
  
  # This class processes URI templates for Routes.
  class DefaultRouteProcessor
    # Returns a pattern for matching variables in Routes.
    def self.match(name)
      return "[^/\\n]*"
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

    # Inspects the internal state of the route.
    def inspect
      return "#<GentleREST::Route:0x#{self.object_id.to_s(16)} " +
        "PATTERN:#{self.pattern.inspect} " +
        "CONTROLLER:#{self.controller.class.to_s}>"
    end
  end
end
