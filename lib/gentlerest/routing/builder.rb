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

require "gentlerest/routing"

module GentleREST
  # This class functions as the default route builder, as well as the base
  # class for all other route builders.
  #
  # A route builder must take a pattern, a controller, and an options Hash
  # as parameters to its initialize method.
  #
  # The route builder's generate method must return the Array of Routes that
  # were built.
  class RouteBuilder
    # Creates a RouteBuilder.  Subclasses should not override this method.
    # If the method must be overridden, it must maintain the same method
    # signature.
    def initialize(pattern, options={})
      @pattern = pattern
      @options = options
    end
    
    attr_reader :pattern, :options
    
    # Generates a single Route object.
    # Subclasses of RouteBuilder should override this method with whatever
    # route building behavior is desired.
    # This method must return an Array of Routes.
    def generate
      new_options = @options.dup
      controller = new_options.delete(:controller)
      return [GentleREST::Route.new(@pattern, controller, new_options)]
    end
  end
end
