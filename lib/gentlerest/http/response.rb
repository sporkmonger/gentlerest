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

require "gentlerest/templates/template"
require "gentlerest/templates/presenter"
require "gentlerest/utilities/context"
require "gentlerest/utilities/normalize"

module GentleREST
  # This is a simple representation of an HTTP response, designed to make
  # JSON serialization as readable as possible.  It exists purely for the
  # purposes of being copied into Mongrel's HttpResponse object.
  class HttpResponse
    # Creates a new HttpResponse object.
    def initialize(status=200, headers={}, body=nil)
      if !status.kind_of?(Fixnum)
        raise TypeError, "Expecting Fixnum, got #{status.class.name}"
      end
      if !headers.kind_of?(Hash)
        raise TypeError, "Expecting Hash, got #{headers.class.name}"
      end
      if !body.kind_of?(String) && body != nil
        raise TypeError, "Expecting String, got #{body.class.name}"
      end
      @status = status
      @headers = {}
      for key, value in headers
        key = GentleREST::Normalization.http_header_normalize(key)
        @headers[key.strip] = value.strip
      end
      @layout = nil
      @body = body
      @history = nil
      @cache = false
      @options = {
        :render_disabled => false,
        :request => nil,
        :controller => nil
      }
    end
  
    # The status code for the HTTP response.
    def status
      return @status
    end
    
    # Sets the response status for the HTTP response.
    def status=(new_status)
      if !new_status.kind_of?(Fixnum)
        raise TypeError, "Expecting Fixnum, got #{new_status.class.name}"
      end
      @status = new_status
    end
    
    # The HTTP headers for the response.
    def headers
      return @headers
    end
    
    # Sets the body of the HTTP response.
    def headers=(new_headers)
      if !new_headers.kind_of?(Hash)
        raise TypeError, "Expecting Hash, got #{new_headers.class.name}"
      end
      @headers = new_headers
    end
    
    # Returns the current mime type of the response.
    def mime_type
      return nil if self.headers["Content-Type"] == nil
      result = self.headers["Content-Type"].scan(/^(.*) *;?/).flatten[0]
      result.strip! if result != nil
      return result
    end
    
    # Returns the current encoding of the response.
    def encoding
      return nil if self.headers["Content-Type"] == nil
      result = self.headers["Content-Type"].scan(
        /^.*? *; *charset=(.*);?/).flatten[0]
      result.strip! if result != nil
      return result
    end
    
    # Sets the mime type for the response to text/html.
    def html
      if self.encoding == nil
        self.headers["Content-Type"] = "text/html"
      else
        self.headers["Content-Type"] = "text/html;charset=#{self.encoding}"
      end
    end
    
    # Sets the mime type for the response to application/xhtml+xml.
    def xhtml
      if self.encoding == nil
        self.headers["Content-Type"] = "application/xhtml+xml"
      else
        self.headers["Content-Type"] =
          "application/xhtml+xml;charset=#{self.encoding}"
      end
    end
    
    # Sets the mime type for the response to application/json.
    def json
      if self.encoding == nil
        self.headers["Content-Type"] = "application/json"
      else
        self.headers["Content-Type"] =
          "application/json;charset=#{self.encoding}"
      end
    end
    
    # Sets the mime type for the response to text/css.
    def css
      if self.encoding == nil
        self.headers["Content-Type"] = "text/css"
      else
        self.headers["Content-Type"] =
          "text/css;charset=#{self.encoding}"
      end
    end

    # Sets the mime type for the response to text/plain.
    def plain_text
      if self.encoding == nil
        self.headers["Content-Type"] = "text/plain"
      else
        self.headers["Content-Type"] = "text/plain;charset=#{self.encoding}"
      end
    end
    
    # Sets the encoding for the response to utf-8.
    def utf8
      if self.mime_type == nil
        self.headers["Content-Type"] = "text/plain;charset=utf-8"
      else
        self.headers["Content-Type"] = "#{self.mime_type};charset=utf-8"
      end
    end
    
    # Returns the redirect history for this response, if any.
    def history
      return @history
    end
    
    # Sets the redirect history for this response.
    def history=(new_history)
      @history = new_history
    end
    
    # Returns true if this response should be cached.
    def cache?
      return @cache
    end
    
    # Set whether or not to cache this response.
    def cache=(new_cache)
      if !([true, false].include?(new_cache))
        raise TypeError,
          "Expected TrueClass or FalseClass, got #{new_cache.class.name}."
      end
      @cache = new_cache
    end
    
    # This method autogenerates a 304 Not Modified response if the 
    # SHA1 of the comparison object's hash matches the If-Modified
    # header of the request.  Returns the status code used in the
    # response.
    def if_modified(object=self.body, &block)
      request = self.render_context.request
      if_modified_header = request.headers["If-Modified"]
      if object == nil
        if self.body == nil
          raise ArgumentError,
            "The body is the default comparison object. " +
            "Comparison object cannot be nil."
        else
          raise ArgumentError, "Comparison object cannot be nil."
        end
      end
      etag = Digest::SHA1.hexdigest(object.hash.to_s)
      self.headers["ETag"] = etag
      if etag == if_modified_header
        # Content is identical.
        self.status = 304
        self.body = ""
      elsif block != nil
        block.call
      end
      return self.status
    end
    
    # The body of the HTTP response.
    def body
      return @body
    end
    
    # Sets the body of the HTTP response.
    def body=(new_body)
      if !new_body.kind_of?(String) && new_body != nil
        raise TypeError, "Expecting String, got #{new_body.class.name}"
      end
      @body = new_body
    end
    
    # Assigns a layout to this response.  Calling this method multiple
    # times will cause the assigned layout to be overwritten with the
    # layout from the second call.
    #
    # Layouts are not rendered until the <code>render</code> method is called.
    # 
    # The method <code>inner_content</code> should be called from within
    # the layout template to render the inner template.
    def layout(template_name, presenter=nil)
      @layout = [template_name, presenter]
      return true
    end
    
    # Renders a named template.  
    def render(template_name, presenter=nil)
      if @render_disabled == true
        raise GentleREST::CachingError,
          "Rendering has been disabled because this response was cached."
      end
      if presenter == nil
        # No Presenter object was supplied, use the controller's default
        # Presenter object or an empty Presenter.
        presenter = GentleREST::Presenter.default_presenter(
          self.options[:controller])
      end
      if @layout == nil
        self.body = GentleREST::Template.render(template_name, presenter)
      else
        outer_template, outer_presenter = @layout
        if outer_presenter == nil
          # Same as above, no layout Presenter supplied, use defaults.
          outer_presenter = GentleREST::Presenter.default_presenter(
            self.options[:controller])
        end
        self.body = GentleREST::Template.render(
          outer_template, outer_presenter, {
            :inner_template => template_name,
            :inner_presenter => presenter
          }
        )
      end
      return self.body
    end
  
    # This method returns a set of options that control how certain
    # response methods behave in certain situations.
    def options # :nodoc:
      return @options
    end
    
    # This method disables rendering.  This method is called to allow
    # the caching of Response objects.
    def disable_rendering # :nodoc:
      @options.clear
      @options[:render_disabled] = true
      @layout = nil
    end
  end
end
