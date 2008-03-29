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

require "gentlerest/directory_lookup"

module GentleREST
  # This class should never be used directly.  It is designed to be
  # subclassed.
  class PersistentHash
    # Creates a new PersistentHash object.
    def initialize
      @accesses = []
      @cache = {}
      if self.class == ::GentleREST::PersistentHash
        raise NotImplementedError,
          "This class may not be directly instantiated. " +
          "It must be subclassed."
      end
    end
    
    # Loads a value from the Hash by doing a lookup on the supplied
    # key object.
    #
    # This method will raise an ArgumentError if the key is not a
    # String object.
    def [](key)
      if !key.kind_of?(String)
        raise TypeError, "The key must be a String object."
      end
      
      # Record access to this key to ensure cache is updated properly.
      self.access(key)
      
      # If we've cached the value internally, use it.
      return @cache[key] if @cache.has_key?(key)
      
      # Value isn't cached, load it from the data store and save it to
      # the memory cache.
      value = self.load_value(key)
      @cache[key] = value
      
      return value
    end
    
    # Stores a value to the Hash for later lookup on the supplied key.
    #
    # This method will raise an ArgumentError if the key is not a
    # String object.
    def []=(key, value)
      if !key.kind_of?(String)
        raise TypeError, "The key must be a String object."
      end
      
      # Record access to this key to ensure cache is updated properly.
      self.access(key)
      
      @cache[key] = value
      self.save_value(key, value)
      
      return value
    end
    alias_method :store, :[]=
    
    # Persists a key / value pair.
    def save_value(key, value)
      raise NotImplementedError,
        "The :save_value method should be overwritten by a subclass."
    end

    # Loads a value.
    def load_value(key)
      raise NotImplementedError,
        "The :load_value method should be overwritten by a subclass."
    end
    
    # Accesses a key and updates the memory cache.
    def access(key)
      @accesses.delete(key)
      @accesses.unshift(key)
      expired_key = @accesses.delete_at(1000)
      self.delete(expired_key) if expired_key != nil
      return key
    end

    # See Hash#update
    #
    # This method will raise an ArgumentError if any key is not a
    # String object.
    def update(hash)
      # TODO: Do we need this?
      
      if !hash.kind_of?(Hash)
        raise TypeError, "can't convert #{hash.class.name} into Hash"
      end
      # Second loop is needed to maintain atomicity.
      for key, value in hash
        if !key.kind_of?(String)
          raise TypeError, "The key must be a String object."
        end
      end
      for key, value in hash
        if key.kind_of?(String)
          self[key] = value
        end
      end
      return self
    end
    
    # Inspects a PersistentHash.
    def inspect
      return @hash.inspect
    end
  end
end
