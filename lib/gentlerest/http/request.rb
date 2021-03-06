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

require "gentlerest/utilities/normalize"

module GentleREST
  # This is a simple representation of an HTTP request, designed to make
  # inspecting a request as simple as possible.  It should only be
  # created if explicitly requested, in order to avoid overhead.
  class HttpRequest
    # Creates a new HttpRequest object.
    def initialize(env={})
      @env = env
      @variables = {}
      @headers = {}
      for key, value in env
        if key =~ /^HTTP_/
          header_name = GentleREST::Normalization.http_header_normalize(
            key[5..-1].split(/[\-_]/).join("-"))
          @headers[header_name] = value
        end
      end
    end
    
    # Returns the wrapped Rack environment Hash.
    attr_reader :env
    
    # Returns the normalized request headers.
    attr_reader :headers

    # Returns the HTTP method as a Symbol object.
    def method
      return @method ||= env["REQUEST_METHOD"].upcase.to_sym
    end

    # Returns the Addressable::URI object for the request.
    def uri
      if !defined?(@uri) || @uri.blank?
        @uri = Addressable::URI.parse(
          env["PATH_INFO"] + env["QUERY_STRING"]
        ).normalize
      end
      return @uri
    end
    
    # Returns the variables Hash for the request.
    def variables
      return @variables
    end
    
    # Sets the variables Hash for the request.
    def variables=(new_variables)
      if !new_variables.kind_of?(Hash)
        raise TypeError, "Expected Hash, got #{new_variables.class.name}."
      end
      @variables = new_variables
    end
  end
end
