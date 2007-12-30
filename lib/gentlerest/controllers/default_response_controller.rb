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

require 'rubygems'
require 'haml'
require 'gentlerest/haml/filters/oneline'
require 'gentlerest/controllers/base_controller'

$TEMPLATE_PATH << File.expand_path(File.join(
  File.dirname(__FILE__), "/../../../templates"
))

module GentleREST
  class DefaultResponseController < GentleREST::BaseController
    def initialize(response_status, *objects)
      @response_status = response_status
      @objects = objects
    end

    attr_reader :response_status
    attr_reader :objects

    action ALL_METHODS do
      # We definitely do not want to cache this response.
      response.cache = false
      
      response.status = response_status
      response.xhtml
      response.utf8
      begin
        response.render("errors/#{response_status}")
      rescue GentleREST::TemplateLoadError
        # Couldn't find the template, time to explode
        response.status = 500
        begin
          response.render("errors/template_missing")
        rescue GentleREST::TemplateLoadError
          response.plain_text
          template_content = "Missing template: #{response_status}"
        end
      end
    end
  end
end
