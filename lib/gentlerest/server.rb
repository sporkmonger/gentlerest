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
require 'mongrel'
require 'gentlerest/utilities/blank'
require 'gentlerest/server/http_handler'
require 'gentlerest/server/http_request'
require 'gentlerest/server/http_response'

module GentleREST
  # Returns a Hash of all running mongrel instances, keyed by server name.
  def self.servers
    if !defined?(@servers) || @servers.blank?
      @servers = {}
    end
    return @servers
  end

  # Returns a named server.
  def self.server(name=:default)
    return self.servers[name]
  end

  # This method starts up a Mongrel server running GentleREST.  Returns the
  # acceptor thread that the server is running in.  Defaults to port 3000.
  # An optional block may be passed to the method which will be run after
  # the server instance has been created, but before Mongrel has started up.
  # This block may be use for setting up routing.
  def self.start(options={}, &block)
    
    # For debugging, mostly
    Thread.abort_on_exception = true
    
    options = self.default_options.merge(options)
    
    server = nil
    if self.servers[options[:name]] == nil
      mongrel_instance = Mongrel::HttpServer.new(
        options[:address], options[:port])
      server = GentleREST::Server.new(
        options[:address], options[:port], mongrel_instance)
      block.call(server) if block != nil
      mongrel_instance.register('/', GentleREST::HttpHandler.new(server))
      mongrel_instance.run
      self.servers[options[:name]] = server
    else
      raise StandardError,
        "The '#{options[:name]}' GentleREST server has already been started."
    end
    return server
  end
  
  # Stops an HTTP server.
  def self.stop(name=:default)
    if self.servers[name] != nil
      self.servers[name].stop
    else
      raise StandardError, "Could not stop the '#{name}' GentleREST server."
    end
  end
  
  # Returns the default options for a server.
  def self.default_options
    if !defined?(@default_options) || @default_options.blank?
      @default_options = {
        :name => :default,
        :address => "0.0.0.0",
        :port => 3000
      }
    end
    return @default_options
  end
  
  # Sets the default options for a server.
  def self.default_options=(new_options)
    if new_options[:name] == nil || new_options[:address] == nil ||
        new_options[:port] == nil
      raise ArgumentError,
        "Options hash must have values for :name, :address, and :port."
    end
    @default_options = new_options
  end

  # This class wraps a Mongrel server instance.
  class Server
    # Creates a new Server instance.
    #
    # Do not call this directly.  Use GentleREST.start to initialize a
    # server.
    def initialize(address, port, mongrel_instance)
      @address = address
      @port = port
      @mongrel_instance = mongrel_instance
    end
    
    # Returns the address the server is bound to.
    attr_reader :address
    
    # Returns the port number the server is running on.
    attr_reader :port
    
    # Returns the instance of the mongrel server.
    attr_reader :mongrel_instance
    
    # Stops the server.
    def stop
      self.mongrel_instance.stop
      GentleREST.servers.delete(GentleREST.servers.index(self))
      return true
    end
    
    # Inspects the server instance.
    def inspect
      return sprintf("#<%s:%#0x ADDR:%s PORT:%d>",
        self.class.to_s, self.object_id, self.address, self.port)
    end
  end
end
