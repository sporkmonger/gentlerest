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

# Effectively borrowed from ActiveSupport's core extensions.  Modified
# slightly.  Didn't want to load all of ActiveSupport since it wasn't
# necessary.  ActiveSupport is Copyright (c) 2005 David Heinemeier Hansson,
# under the MIT license.

class Object #:nodoc:
  # "", "   ", nil, [], and {} are blank
  def blank?
    if respond_to?(:empty?) && respond_to?(:strip)
      return (empty? || strip.empty?)
    elsif respond_to?(:empty?)
      return empty?
    else
      !self
    end
  end
end

class NilClass #:nodoc:
  def blank?
    return true
  end
end

class FalseClass #:nodoc:
  def blank?
    return true
  end
end

class TrueClass #:nodoc:
  def blank?
    return false
  end
end

class Array #:nodoc:
  alias_method :blank?, :empty?
end

class Hash #:nodoc:
  alias_method :blank?, :empty?
end

class String #:nodoc:
  def blank?
    return (empty? || strip.empty?)
  end
end

class Numeric #:nodoc:
  def blank?
    return false
  end
end
