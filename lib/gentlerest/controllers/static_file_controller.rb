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

require "rubygems"
require "addressable/uri"
require "mime/types"
require "gentlerest/controllers/base_controller"

module GentleREST
  class StaticFileController < GentleREST::BaseController
    def initialize(path_pattern)
      @path_pattern = path_pattern
    end

    attr_reader :path_pattern

    action [:GET] do
      response.status = 200
      path_uri = Addressable::URI.expand_template(
        @path_pattern, request.variables)
      file_path = File.expand_path(path_uri.path)
      response.headers["Content-Type"] = MIME::Types.type_for(file_path).to_s
      response.body = File.open(file_path, "r") do |file|
        file.read
      end
      response.cache = true
      return nil
    end
  end
end
