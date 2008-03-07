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
require "digest/sha1"
require "gentlerest/errors"
require "gentlerest/hashes/text_hash"

module GentleREST
  # This class represents a single user's session state.
  class Session
    # Returns the current session store.
    def self.store
      if !defined?(@store) || @store == nil
        raise StandardError, "The session store has not been set yet."
      end
      return @store
    end

    # Sets the session store to a new object.
    #
    # Any object which responds to the [], []=, and update messages may
    # be used as a session store.  The session store object should behave
    # like a Hash object.
    def self.store=(new_store)
      # TODO: Figure out which messages we're actually going to send
      # to this object and check for their presence.
      unless new_store.respond_to?(:[]) &&
          new_store.respond_to?(:[]=) &&
          new_store.respond_to?(:update)
        raise TypeError,
          "The session store must respond to the [] and []= messages."
      end
      @store = new_store
    end
    
    # Loads session data in the form of a Hash object into the current
    # session store.  Typically, this data will be deserialized from JSON.
    def self.load(session_data)
      normalized_session_data = {}
      session_data.each do |key, value|
        unless key.kind_of?(String) && key =~ /\d+/
          raise ArgumentError, "Invalid session id: #{key.inspect}"
        end
        if !value.kind_of?(Hash) && !value.respond_to?(:to_hash)
          raise ArgumentError, "Invalid session state: #{value.inspect}"
        elsif value.respond_to?(:to_hash)
          value = value.to_hash
        end
        normalized_value = GentleREST::TextHash.new
        normalized_value.update(value)
        normalized_session_data[key] = normalized_value
      end
      return self.store.update(normalized_session_data)
    end
    
    # Creates a new Session object.  If the optional session id is given,
    # the session will be loaded from the session store.
    def initialize(session_id=nil)
      if session_id != nil
        @session_id = session_id
        @state = self.store[session_id]
      end
    end
    
    # Returns the session id for this session.
    def session_id
      if !defined?(@session_id) || @session_id == nil
        # 160-bit random number
        @session_id =
          rand(1461501637330902918203684832716283019655932542975).to_s(16)
      end
      return @session_id
    end
    
    # Returns a Hash object that represents the current session state.
    def state
      if !defined?(@state) || @state == nil
        @state = GentleREST::TextHash.new
      end
      return @state
    end
    
    # Saves the Session object to the session store.  Nothing will happen
    # if the session state wasn't used.
    def save
      unless self.state.empty?
        self.class.store[self.session_id] = self.state
      end
    end
  end
end
