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

require "gentlerest/server/http_request"

module GentleREST
  class HttpRequest
    # Returns an Array of known automated bot User-Agent strings.
    # This list is used to determine if a request was made by a bot.
    def self.robots
      if !defined?(@robots) || @robots == nil
        @robots = [
          "bot", "Google", "Pingdom", "GIGRIB", "Baidu", "SiteUptime",
          "Slurp", "WordPress", "ZIBB", "ZyBorg"
        ]
      end
      return @robots
    end

    # Returns true if the request was made by a known automated bot.
    def robot?
      user_agent = self.headers["User-Agent"]
      escaped_bots = GentleREST::HttpRequest.robots.map do |bot|
        Regexp.escape(bot)
      end
      bots_regexp = Regexp.new(
        "(#{escaped_bots.join("|")})", Regexp::IGNORECASE)
      return !!(user_agent =~ bots_regexp)
    end
  end
end