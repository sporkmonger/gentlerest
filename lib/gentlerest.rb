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

$:.unshift(File.expand_path(File.dirname(__FILE__)))
$: << File.expand_path(File.join(
  File.dirname(__FILE__), "/../vendor/mime_types/lib"))
$: << File.expand_path(File.join(
  File.dirname(__FILE__), "/../applications"))
$:.uniq!

require "rubygems"
require "rack"
require "gentlerest/version"
require "gentlerest/errors"
require "gentlerest/locator"
require "gentlerest/utilities/bind"
require "gentlerest/utilities/blank"
require "gentlerest/http/request"
require "gentlerest/http/response"
require "gentlerest/instance"
require "gentlerest/session"
require "gentlerest/rack/gentlerest_adapter"
require "gentlerest/routing"
require "gentlerest/templates/template"
require "gentlerest/controllers/base_controller"
require "gentlerest/controllers/default_response_controller"
require "gentlerest/controllers/redirect_controller"
require "gentlerest/controllers/static_file_controller"
