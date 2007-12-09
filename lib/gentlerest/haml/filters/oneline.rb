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

# module Haml
#   module Filters
#     # This code apparently won't be useful until HAML 2.0 since filters
#     # currently don't have access to the scope object, and without
#     # the scope object to do the sub-render, you're kinda screwed if you want
#     # to do anything dynamic within the filter.
#     class OneLine
#       def initialize(text)
#         @text = text
#       end
# 
#       def render
#         return
#           Haml::Engine.new(@text).render.gsub(/^\s+/, "").gsub(/[\r\n]+/, "")
#       end
#     end
#   end
# end

# if filter.instance_method(:render).arity == 0
#   filtered = filter.new(@filter_buffer).render
# 
#   unless filter == Haml::Filters::Preserve
#     push_text(filtered.rstrip.gsub("\n", "\n#{'  ' * @output_tabs}"))
#   else
#     push_silent("_hamlout.buffer << #{filtered.dump} << \"\\n\"\n")
#   end
# else
#   push_silent(
#     "haml_temp = #{filter.name}" +
#     ".new(#{@filter_buffer.inspect})" +
#     ".render(self).rstrip" +
#     ".gsub(\"\\n\", \"\\n#{'  ' * @output_tabs}\")\n", true)
#   @precompiled <<
#     "haml_temp = _hamlout.push_script(haml_temp, false, nil)\n"
# end

module Haml
  module Filters
    class OneLine
      def initialize(text)
        @text = text
      end

      def render(scope = Object.new)
        return Haml::Engine.new(@text).render(
          scope).gsub(/^\s+/, "").gsub(/[\r\n]+/, "")
      end
    end
  end
end
