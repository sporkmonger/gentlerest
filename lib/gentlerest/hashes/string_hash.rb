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

module GentleREST
  # This class shares all of the same methods as the Hash class, and
  # exists largely to prevent surprise when a JSON serialization
  # converts Symbol objects to String objects.
  class StringHash < Hash
    include Enumerable

    alias_method :internal_store, :store
    protected :internal_store
    alias_method :internal_delete, :delete
    protected :internal_delete

    # Creates a new StringHash object.
    def initialize
      super(nil)
    end
    
    # See Hash#[]=
    #
    # This method will raise an ArgumentError if either the key or the value
    # is a non-string object.
    def []=(key, value)
      if !key.kind_of?(String)
        raise TypeError, "The key must be a String object."
      end
      return self.internal_store(key, value)
    end
    alias_method :store, :[]=

    # See Hash#update
    #
    # This method will raise an ArgumentError if any key or value
    # is a non-string object.
    def update(hash)
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
  end
end
