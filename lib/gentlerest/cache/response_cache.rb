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

require "gentlerest/http/response"
require "digest/sha1"

module GentleREST
  class HttpResponseCache
    # Initializes the HttpResponseCache.
    def self.startup
      if !defined?(@cache_dir) || @cache_dir == nil
        if ENV['GENTLE_ROOT'] != nil
          if !File.exists?(File.join(ENV['GENTLE_ROOT'], "/tmp"))
            Dir.mkdir(File.join(ENV['GENTLE_ROOT'], "/tmp"))
          end
          if !File.exists?(File.join(ENV['GENTLE_ROOT'], "/tmp/cache"))
            Dir.mkdir(File.join(ENV['GENTLE_ROOT'], "/tmp/cache"))
          end
          @cache_dir =
            File.expand_path(File.join(ENV['GENTLE_ROOT'], "/tmp/cache"))
        else
          @cache_dir = nil
        end
      end
    end
    
    # Puts a response into the cache.
    def self.cache(uri, response)
      # WARNING: For performance reasons, startup is not called from here.
      # However, if startup is not called before this method is executed,
      # the cache will be disabled.
      return nil if !defined?(@cache_dir) || @cache_dir == nil
      
      lookup = Digest::SHA1.hexdigest(uri.to_s).to_s[0...36]
      cache_path = File.join(
        @cache_dir, lookup.scan(/.{12}/).join("/") + ".http")
      
      # Create intermediate directories
      intermediate_path = File.dirname(File.dirname(cache_path))
      if !File.exists?(intermediate_path)
        Dir.mkdir(intermediate_path)
      end
      intermediate_path = File.dirname(cache_path)
      if !File.exists?(intermediate_path)
        Dir.mkdir(intermediate_path)
      end
      
      # Ditch context objects before dumping.
      response.disable_rendering()
      
      File.open(cache_path, "w") do |file|
        file.write(Marshal.dump(response))
      end
    end
    
    # Retrieves a response from the cache if it's there.  Returns nil if
    # no response is present.
    def self.retrieve(uri)
      # WARNING: For performance reasons, startup is not called from here.
      # However, if startup is not called before this method is executed,
      # the cache will be disabled.
      return nil if @cache_dir == nil
      
      lookup = Digest::SHA1.hexdigest(uri.to_s).to_s[0...36]
      cache_path = File.join(
        @cache_dir, lookup.scan(/.{12}/).join("/") + ".http")
      return nil if !File.exists?(cache_path)
      data = File.open(cache_path, "r") do |file|
        file.read
      end
      begin
        response = Marshal.load(data)
      rescue ArgumentError
        File.delete(cache_path) rescue nil
        return nil
      end
      
      # Don't put the response right back in the cache, it's already there
      response.cache = false
      
      return response
    end
  end
end
