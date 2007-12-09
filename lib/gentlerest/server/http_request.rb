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

module GentleREST
  # This is a simple representation of an HTTP request, designed to make
  # inspecting a request as simple as possible.  It should only be
  # created if explicitly requested, in order to avoid overhead.
  class HttpRequest
    # Creates a new HttpRequest object.
    def initialize(mongrel_request)
      @mongrel_request = mongrel_request
      @variables = {}
    end
    
    # Returns the wrapped Mongrel request object.
    attr_reader :mongrel_request

    # Returns the HTTP method as a Symbol object.
    def method
      return @method ||=
        @mongrel_request.params["REQUEST_METHOD"].upcase.to_sym
    end

    # Returns the Addressable::URI object for the request.
    def uri
      if !defined?(@uri) || @uri.blank?
        @uri = Addressable::URI.parse(@mongrel_request.params["REQUEST_URI"])
      end
      return @uri
    end
    
    # Returns the variables Hash for the request.
    attr_reader :variables
    
    # Sets the variables Hash for the request.
    attr_writer :variables
  end
end
