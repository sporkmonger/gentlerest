#--
# GentleREST, Copyright (c) 2007-2008 Robert Aman
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
require "gentlerest/controllers/base_controller"

module GentleREST
  class RedirectController < GentleREST::BaseController
    def initialize(location_pattern, redirect_type=:found)
      @location_pattern = location_pattern
      @redirect_type = redirect_type
      if ![:permanent, :found, :see_other, :temporary].include?(redirect_type)
        raise ArgumentError,
          "Expected :permanent, :found, :see_other, or :temporary, " +
          "got #{@redirect_type.inspect}"
      end
    end

    attr_reader :location_pattern
    attr_reader :redirect_type

    action ALL_METHODS do
      case @redirect_type
      when :permanent
        response.status = 301
      when :found
        response.status = 302
      when :see_other
        response.status = 303
      when :temporary
        response.status = 307
      else
        raise ArgumentError,
          "Expected :permanent, :found, :see_other, or :temporary, " +
          "got #{@redirect_type.inspect}"
      end
      location_uri = Addressable::URI.expand_template(
        @location_pattern, request.variables)
      response.headers["Location"] = location_uri.to_s
      
      # Use the default response controller to generate the
      # body content.
      default_response_controller =
        GentleREST::DefaultResponseController.new(
          response.status, location_uri.to_s)
      templated_response = default_response_controller.dispatch_action(
        request, GentleREST::HttpResponse.new)

      # If an error occurred while getting the templated response,
      # change status code to match.
      if (templated_response.status.to_i / 100) == 5
        response.status = templated_response.status
      end
      
      # Copy the headers and body from the default response controller.
      response.headers = templated_response.headers.merge(response.headers)
      response.body = templated_response.body
    end
  end
end
