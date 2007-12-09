#--
# GentleREST, Copyright (c) 2007 Robert Aman
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
require 'gentlerest/utilities/indentation'

module GentleREST
  class ErrorController < GentleREST::BaseController
    def initialize(error)
      @error = error
    end

    attr_reader :error

    action(ALL_METHODS) do
      response.status = 500
      response.xhtml
      response.utf8
      response.body = Haml::Engine.new((
        <<-HAML
          !!! XML
          <!DOCTYPE html>
          %html{ html_attrs }
            %head
              %title= "500 Internal Server Error - " + error.class.name
              %style
                :plain                  
                  * {
                    font-size: 100%;
                    margin: 0;
                    padding: 0;
                  }

                  body {
                    font-family: lucida grande, verdana, sans-serif;
                    margin: 1em;
                  }

                  a {
                    color: #880000;
                  }

                  a:visited {
                    color: #888888;
                  }

                  h1 {
                    font-size: 2em;
                    margin: 0 0 0.8em 0;
                  }

                  h2 {
                    font-size: 1em;
                    margin: 0.8em 0;
                  }

                  p {
                    margin: 0.8em 0;
                  }

                  ul {
                    font-size: 0.9em;
                    margin: 0 0 0 1.5em;
                  }
                  
                  pre {
                    padding: 1em;
                    border: 2px solid #AAAAAA;
                    background-color: #888888;
                    overflow: auto;
                  }

                  #content {
                    padding: 0 0.8em;
                    background-color: #AA5852;
                    border: 2px solid #C2645D;
                  }

                  @media print {
                    a {
                      text-decoration: none;
                      color: #000000;
                    }
                  }
            %body
              #header
                %h1 500 Internal Server Error
                %h2= error.class.name
              #content
                %p An error has occurred while processing the request:
                %p= error.message
                - if error.respond_to?(:backtrace) && error.backtrace != nil
                  %p
                    :oneline
                      %pre
                        %code
                          = preserve(error.backtrace.join("\\n"))
                - else
                  %p Backtrace is unavailable.
        HAML
      ).unindent(10), {
        :attr_wrapper => "\"",
        :filters => {"oneline" => Haml::Filters::OneLine}
      }).render(self)
    end
  end
end
