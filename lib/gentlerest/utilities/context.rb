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
  # +Context+ objects are throw-away objects designed to be the target of
  # a +Proc+ binding.  They can wrap an arbitrary object, to which all
  # undefined messages will be sent.  Typically, +Context+ objects will have
  # several singleton methods defined on them.  Additionally, +Context+
  # objects may optionally capture the output of any code executed within
  # them.
  class Context
    # Remove any methods that would interfere with relaying messages to
    # the wrapped object.
    instance_methods.each do |name|
      if !(["__id__", "__send__", "ancestors", "class", "class_eval",
          "class_variables", "const_defined?", "const_get", "const_missing",
          "const_set", "constants", "extend", "freeze", "frozen?", "id",
          "include", "include?", "included_modules", "inspect",
          "instance_eval", "instance_method", "instance_methods",
          "instance_of?", "instance_variable_get", "instance_variable_set",
          "instance_variables", "is_a?", "kind_of?", "local_methods",
          "method", "method_defined?", "methods", "module_eval", "new",
          "object_id", "private_class_method", "private_instance_methods",
          "private_method_defined?", "private_methods",
          "protected_instance_methods", "protected_method_defined?",
          "protected_methods", "public_class_method",
          "public_instance_methods", "public_method_defined?",
          "public_methods", "require", "require_gem", "send",
          "singleton_methods", "superclass", "taint", "tainted?", "type",
          "untaint"].include?(name))
        undef_method(name)
      end
    end

    # Creates a context object, and optionally wraps an arbitrary object to
    # which any missing methods will be relayed.
    def initialize(wrapped_object=nil, options={})
      @options = {
        :capture_output => false
      }.merge(options)
      @wrapped_object = wrapped_object
      for var in @wrapped_object.instance_variables
        next if var == "@wrapped_object"
        next if var == "@options"
        next if var == "@output_buffer"
        value = @wrapped_object.instance_variable_get(var)
        self.instance_variable_set(var, value)
      end
      if @options[:capture_output]
        class <<self
          # Output is redirected to the output buffer.
          def print(*params)
            self.output_buffer.print(*params)
          end

          # Output is redirected to the output buffer.
          def printf(*params)
            self.output_buffer.printf(*params)
          end

          # Output is redirected to the output buffer.
          def puts(*params)
            self.output_buffer.puts(*params)
          end

          # Output is redirected to the output buffer.
          def putc(*params)
            self.output_buffer.putc(*params)
          end

          # Output is redirected to the output buffer.
          def write(*params)
            self.output_buffer.write(*params)
          end
        end
      end
    end
    
    # An arbitrary object wrapped by the +Context+.  If this is set to
    # anything other than +nil+, any missing methods will be relayed to this
    # object.
    attr_reader :wrapped_object
    
    # Returns the execution context for the Context object.
    def binding
      # Kind of a hack to get around the fact that we're overriding the
      # private Kernel version of the binding method.
      return (lambda {}).binding
    end
    
    # Returns the +StringIO+ output buffer for whatever output was generated
    # within the +Proc+ that was bound to the +Context+ instance.
    def output_buffer
      if !defined?(@output_buffer) || @output_buffer == nil
        require 'stringio'
        @output_buffer = StringIO.new
      end
      return @output_buffer
    end
    
    # Returns true if the Context object can respond to the message.
    def respond_to?(message)
      return true if self.methods.include?(message.to_s)
      return @wrapped_object.respond_to?(message) if @wrapped_object != nil
      return false
    end
    
    # Relays any missing methods to the wrapped object, or raises an error if
    # there is no wrapped object.
    def method_missing(message, *params, &block)
      if @wrapped_object != nil
        return @wrapped_object.send(message, *params, &block)
      else
        raise NoMethodError,
          "undefined method `#{message.to_s}' for " +
          "#{self.inspect}:#{self.class}"
      end
    end
  end
end
