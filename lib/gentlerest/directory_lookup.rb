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

require "digest/sha1"

module GentleREST
  # A DirectoryLookup object is a simple system for providing fast, scalable
  # access to an object stored on disk by its key.
  class DirectoryLookup
    # Creates a new DirectoryLookup object with the given base directory.
    def initialize(base)
      unless base.kind_of?(String)
        raise TypeError, "Expected String, got #{base.class.name}."
      end
      @base = base
    end

    # Returns the base directory for this lookup system.
    def base
      return @base
    end
    
    # Finds the location the object should be stored in by the given key.
    # Creates any intermediate directories if they don't exist.
    def lookup(key)
      # It would be nice if we could use key.hash here, but we can't
      # because the default implementation of hash is simply: self.object_id
      key_id = key.to_s + key.class.name
      
      # Directories are split into 4 groups, each with a length of 3
      # characters, for a total of 4096 entries per directory.  This
      # should limit issues with file systems that can't handle large
      # numbers of files or subdirectories within one directory while
      # maintaining fast lookup speed.  Collisions should be limitted
      # because there are over 68 billion 
      lookup = Digest::SHA1.hexdigest(key_id).to_s[0...12]
      lookup_path = File.join(
        self.base, lookup.scan(/.{3}/).join("/") + "/")
      
      # Recursively create intermediate directories
      intermediate_path = lookup_path.dup
      mkdir_parent = lambda do |path|
        if !File.exist?(File.dirname(path))
          mkdir_parent.call(File.dirname(path))
        end
        if !File.exist?(path)
          Dir.mkdir(path)
        end
      end
      mkdir_parent.call(intermediate_path)
      return lookup_path
    end
  end
end
