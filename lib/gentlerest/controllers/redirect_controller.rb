#--
# GentleREST, Copyright (c) 2007 Robert Aman
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
require 'haml'
require 'addressable/uri'
require 'gentlerest/controllers/base_controller'

module GentleREST
  class RedirectController < GentleREST::BaseController
    def initialize(location_pattern, redirect_type=:found)
      @location_pattern = location_pattern
      @redirect_type = redirect_type
    end

    attr_reader :location_pattern
    attr_reader :redirect_type

    action(ALL_METHODS) do
      case @redirect_type
      when :permanent
        response.status = 301
      when :found
        response.status = 302
      when :temporary
        response.status = 307
      else
        raise ArgumentError,
          "Expected :permanent, :found, or :temporary, " +
          "got #{@redirect_type.inspect}"
      end
      location_uri = Addressable::URI.expand_template(
        @location_pattern, request.variables)
      response.headers["Location"] = location_uri.to_s
      return ""
    end
  end
end
