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
  module ProfileWriter
    def self.write(result)
      require "ruby-prof"

      if ENV["PROFILE_PRINTER"] == "html"
        printer = RubyProf::GraphHtmlPrinter.new(result)

        if ENV['GENTLE_ROOT'] != nil
          if !File.exist?(File.join(ENV['GENTLE_ROOT'], "/tmp"))
            Dir.mkdir(File.join(ENV['GENTLE_ROOT'], "/tmp"))
          end
          if !File.exist?(File.join(ENV['GENTLE_ROOT'], "/tmp/profile"))
            Dir.mkdir(File.join(ENV['GENTLE_ROOT'], "/tmp/profile"))
          end
          profile_dir =
            File.expand_path(
              File.join(ENV['GENTLE_ROOT'], "/tmp/profile"))
        else
          abort(
            "Could not find profile directory.  " +
            "Root directory was not set."
          )
        end

        output_filename = (Time.now.to_f * 10000).to_i.to_s + ".html"
        File.open(File.join(profile_dir, output_filename), "w") do |file|
          printer.print(file, 0)
        end
      else
        printer = RubyProf::FlatPrinter.new(result)
        printer.print(STDOUT, 0)
      end
    end
  end
end
