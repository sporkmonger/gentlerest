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

class String #:nodoc:
  # Indents a String by a specified number of spaces.  Defaults to a two
  # space indentation.
  def indent(spaces=2)
    if spaces == 0
      return self
    elsif spaces < 0
      return self.unindent(-spaces)
    else
      return (self.split("\n").map do |line|
        (" " * spaces) + line
      end).join("\n")
    end
  end

  # Unindents a String by a specified number of spaces.  Specifying :begin
  # causes the string to be unindented all the way to the beginning.  Defaults
  # to a two space indentation.
  def unindent(spaces=2)
    if spaces == 0
      return self
    elsif spaces != :begin && spaces < 0
      return self.indent(-spaces)
    elsif spaces == :begin
      shortest = nil
      for line in self.split("\n")
        if line.strip != ""
          indent = line.scan(/^\s*/)[0].gsub(/\t/, "  ").size
          shortest = indent if shortest == nil || indent < shortest
        end
      end
      return (self.split("\n").map do |line|
        line.gsub(/\t/, "  ").gsub(/^[ ]{0,#{shortest}}/, "")
      end).join("\n")
    else
      return (self.split("\n").map do |line|
        line.gsub(/\t/, "  ").gsub(/^[ ]{0,#{spaces}}/, "")
      end).join("\n")
    end
  end
end
