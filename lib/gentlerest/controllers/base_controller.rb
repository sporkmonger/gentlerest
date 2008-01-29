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

require 'gentlerest/errors'
require 'gentlerest/utilities/context'

module GentleREST
  class BaseController
    ALL_METHODS = [:GET, :HEAD, :POST, :PUT, :DELETE]

    # This class represents a stored controller action.
    class ControllerAction
      def initialize(methods, variables, action)
        if !methods.kind_of?(Array)
          raise TypeError, "Accepted methods must be an Array."
        end
        if !variables.kind_of?(Hash)
          raise TypeError, "Variables must be supplied as a Hash."
        end
        if !action.kind_of?(Proc)
          raise TypeError, "The action must be supplied as a Proc."
        end
        variables.each do |key, value|
          if !key.kind_of?(String)
            raise TypeError, "Variable names must be Strings."
          end
          if !value.kind_of?(String)
            raise TypeError, "Variable values must be Strings."
          end
        end
        @methods = methods
        @variables = variables
        @action = action
      end
      
      # Returns an Array of HTTP methods accepted by this action.
      attr_reader :methods
      
      # Returns a Hash of String key-value pairs that this action
      # requires in order to fire.
      attr_reader :variables
      
      # Returns the Proc object that is called when this action fires.
      attr_reader :action
    end
    
    # This class represents a behavioral hook for a controller.
    class ControllerHook < ControllerAction
      def initialize(hook, variables, action)
        if !hook.kind_of?(Symbol)
          raise TypeError, "The hook must be a Symbol."
        end
        super([], variables, action)
        @hook = hook
      end

      # Returns the hook name.
      attr_reader :hook
    end
    
    # Returns an Array of actions registered by this controller.
    def self.actions
      return @actions ||= []
    end

    # Returns an Array of hooks registered by this controller.
    def self.hooks
      return @hooks ||= []
    end
    
    # Registers an action on this controller.
    def self.action(methods=[:GET], variables={}, &action)
      methods = [methods] if methods.kind_of?(Symbol)
      methods = methods.flatten
      self.actions << ControllerAction.new(methods, variables, action)
    end

    # Registers a hook on this controller.
    def self.hook(hook, variables={}, &action)
      self.hooks << ControllerHook.new(hook, variables, action)
    end

    # Registers a before hook on this controller.
    def self.before(variables={}, &action)
      self.hooks << ControllerHook.new(:before, variables, action)
    end

    # Registers an after hook on this controller.
    def self.after(variables={}, &action)
      self.hooks << ControllerHook.new(:after, variables, action)
    end
    
    # Locates the appropriate action on the controller for this request,
    # then runs the action within a custom execution context.
    def dispatch_action(http_request, http_response)
      selected_action = nil

      # We don't want ancestor classes to overwrite existing actions.
      for klass in self.class.ancestors
        break if !klass.respond_to?(:actions)

        # Actions need to be in order, largest variable hash first, otherwise
        # the default action might always fire even when a better match is
        # available.
        sorted_actions = klass.actions.sort do |a, b|
          b.variables.size <=> a.variables.size
        end

        for action in sorted_actions
          if http_request.variables.merge(action.variables) ==
              http_request.variables &&
              action.methods.include?(http_request.method)
            selected_action = action
            break
          end
        end
        break if selected_action != nil
      end


      if selected_action != nil
        context = GentleREST::Context.new(self, :capture_output => false)
        (class <<context; self; end).send(:define_method, :request) do
          http_request
        end
        (class <<context; self; end).send(:define_method, :response) do
          http_response
        end
        http_response.render_context = context

        # Find any matching hooks.
        matching_hooks = []
        if !self.class.hooks.empty?
          # Unlike actions, hooks do not need to be in order, because
          # all matching hooks fire.
          
          # Load all hooks, including those from parent classes.
          hook_set = []
          for klass in self.class.ancestors
            break if !klass.respond_to?(:hooks)
            hook_set.concat(klass.hooks)
          end

          for hook in hook_set
            if http_request.variables.merge(hook.variables) ==
                http_request.variables
              matching_hooks << hook
            end
          end

          # Execute before hooks.
          for hook in (matching_hooks.reject { |h| h.hook != :before })
            hook.action.bind(context).call
          end
        end
        
        # Execute the action Proc within the custom execution context.
        result_body = selected_action.action.bind(context).call

        # If the response body has not been changed and the return value
        # of the Proc was a String, assign its value to the response body.
        if result_body.kind_of?(String) && http_response.body == nil
          http_response.body = result_body
        end

        # Execute after hooks.
        for hook in (matching_hooks.reject { |h| h.hook != :after })
          hook.action.bind(context).call
        end

        return http_response
      else
        raise NoMatchingActionError,
          "Could not find an action that matched the request's variables."
      end
    end
  end
end
