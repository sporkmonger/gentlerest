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
require "gentlerest/utilities/blank"
require "gentlerest/rack/gentlerest_adapter"
require "gentlerest/http/request"
require "gentlerest/http/response"

module GentleREST
  # Returns an Array of all running GentleREST instances.
  def self.instances
    if !defined?(@instances) || @instances == nil
      @instances = []
    end
    return @instances
  end

  # This method configures a GentleREST instance.
  # An optional block may be passed to the method which will be run after
  # the instance has been created, but before the server starts handling
  # requests.  This block is used to set up routing.
  def self.configure(&block)
    instance = GentleREST::Instance.new
    block.call(instance) if block != nil
    self.instances << instance

    return instance
  end
  
  # Stops an HTTP server.
  def self.stop(name=:default)
    if self.servers[name] != nil
      self.servers[name].stop
    else
      raise StandardError, "Could not stop the '#{name}' GentleREST server."
    end
  end

  # This class represents a single GentleREST instance.
  #
  # Do not instantiate this class directly.  Use GentleREST.configure
  # to initialize a server.
  class Instance
    # Returns the Rack adapter for this GentleREST instance.
    def adapter
      if !defined?(@adapter) || @adapter == nil
        @adapter = Rack::Adapter::GentleREST.new(self)
      end
      return @adapter
    end
    
    # Inspects the server instance.
    def inspect
      return sprintf("#<%s:%#0x>", self.class.to_s, self.object_id)
    end
  end
end
