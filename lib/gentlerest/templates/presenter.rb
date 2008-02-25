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

require "forwardable"
require "gentlerest/errors"
require "gentlerest/http/response"
require "gentlerest/utilities/context"

module GentleREST
  # The Presenter class provides a simple base class for other Presenter
  # classes to extend.  Whenever a controller action renders a template that
  # requires dynamic application data, a Presenter instance should be passed
  # as a parameter to the render method.
  class Presenter
    extend Forwardable
    
    # This method returns the default presenter object to use if no presenter
    # object was supplied.  Optionally takes a controller object as a
    # parameter.  If the controller's class respond's to the :presenter
    # message, it will use that value unless it returns nil.
    def self.default_presenter(controller=nil)
      presenter = nil
      # Use the controller's default presenter object.
      if controller != nil
        if controller.class.respond_to?(:presenter)
          presenter = controller.class.presenter
        end
      end
      if presenter == nil
        # The controller's default presenter object was nil, so create our
        # own presenter.
        presenter = GentleREST::Presenter.new
      end
      if !presenter.kind_of?(GentleREST::Presenter)
        raise TypeError,
          "Expected object of type GentleREST::Presenter, " +
          "got #{presenter.class.name}.  Check controller."
      end
      return presenter
    end
    
    # Returns the template path for the enclosed template.
    def inner_template
      @inner_template ||= nil
      return @inner_template
    end
    
    # Sets the template path for the enclosed template.
    def inner_template=(new_inner_template)
      if new_inner_template != nil &&
          !new_inner_template.kind_of?(String)
        raise TypeError,
          "Expected object of type String, " +
          "got #{new_inner_template.class.name}."
      end
      @inner_template = new_inner_template
    end
    
    # Returns the Presenter object for the enclosed template.
    def inner_presenter
      @inner_presenter ||= GentleREST::Presenter.new
      return @inner_presenter
    end
    
    # Sets the Presenter object for the enclosed template.
    def inner_presenter=(new_inner_presenter)
      if new_inner_presenter != nil &&
          !new_inner_presenter.kind_of?(GentleREST::Presenter)
        raise TypeError,
          "Expected object of type GentleREST::Presenter, " +
          "got #{new_inner_presenter.class.name}."
      end
      @inner_presenter = new_inner_presenter
    end
    
    # If this Presenter is for a layout template, this method returns the
    # content the layout template will wrap.
    def inner_content
      return "" if inner_template == nil
      if inner_presenter == nil
        return GentleREST::Template.render(inner_template)
      else
        return GentleREST::Template.render(inner_template, inner_presenter)
      end
    end

    # This method wraps a block of preformatted text with preformat elements,
    # removes all instances of the carriage return character, and replaces
    # all instances of the newline character with a character entity to allow
    # for sane indentation around preformatted elements.
    def preformat(text)
      return "<pre>" + text.gsub("\r", "").gsub("\n", "&#x000A;") + "</pre>"
    end

    # This method escapes potentially dangerous special characters that appear
    # in text that may have been supplied by an external source.  This method
    # should be used on any user input to avoid a cross-site scripting
    # attack.
    def escape(text)
      if !text.kind_of?(String)
        if text.respond_to?(:to_str)
          text = text.to_str
        else
          text = test.to_s
        end
      end
      # TODO: Verify that this is sufficient, gut feeling says no.
      text.gsub(/\</, "&lt;")
    end
    alias_method :h, :escape
  end
end
