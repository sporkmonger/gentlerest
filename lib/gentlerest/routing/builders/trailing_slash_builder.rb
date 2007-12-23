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

require 'gentlerest/routing'

module GentleREST
  # This class builds routes that redirect from URIs without trailing slashes
  # to URIs that have trailing slashes.
  class TrailingSlashBuilder < GentleREST::RouteBuilder
    # Generates two Route objects: the main Route object, and a redirecting
    # Route that permanently redirects any requests that match the pattern
    # without its trailing slash to the actual resource.
    def generate
      if @pattern[-1] == 47 || @pattern[-1] == "/"
        primary_pattern = @pattern
        slashless_pattern = @pattern[0...-1]
      else
        primary_pattern = @pattern + "/"
        slashless_pattern = @pattern
      end
      return [
        GentleREST::Route.new(
          primary_pattern,
          @controller,
          @options),
        GentleREST::Route.new(
          slashless_pattern,
          GentleREST::RedirectController.new(primary_pattern, :permanent),
          @options)
      ]
    end
  end
end
