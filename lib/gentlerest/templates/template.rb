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

# This variable stores a list of all paths to search for when locating a
# named template.
$TEMPLATE_PATH = ["."]

module GentleREST
  class Template
    # Registers a template type.  Takes a symbol naming the type, and a block
    # which takes a String as input and an Object to use as the execution
    # context and returns the rendered template output as a String.
    # The block should ensure that all necessary libraries are loaded.
    def self.register_type(type, &block)
      if !defined?(@type_map) || @type_map == nil
        @type_map = {}
      end

      # Normalize to symbol
      type = type.to_s.to_sym
      @type_map[type] = block
      return nil
    end
    
    # Returns a list of registered template types.
    def self.types
      if !defined?(@type_map) || @type_map == nil
        @type_map = {}
      end
      return @type_map.keys
    end
    
    # Returns the processor Proc for the specified type.
    #
    # Raises an ArgumentError if the type is invalid.
    def self.processor(type)
      if !defined?(@type_map) || @type_map == nil
        @type_map = {}
      end

      # Normalize to symbol
      type = type.to_s.to_sym
      
      if !self.types.include?(type)
        raise ArgumentError,
          "Unrecognized template type: #{type.inspect}\n" +
          "Valid types: " +
          "#{(self.class.types.map {|t| t.inspect}).join(", ")}"
      end
      
      return @type_map[type]
    end
    
    # Renders a template.  Takes a Symbol identifying the type, and
    # optionally take a context to 
    #
    # Raises an ArgumentError if the type is invalid.
    def self.render(name, context=Object.new, options={})
      # Locate the template.
      path = nil
      for load_path in $TEMPLATE_PATH
        full_name = File.join(load_path, name)
        templates = Dir.glob(full_name + "*")
        if templates.include?(full_name)
          # Use an exact match if we can.
          template = full_name
        else
          # Otherwise, select the first template matched.
          template = templates.first
        end
        if template != nil
          path = template
          break
        end
      end
      
      if path == nil
        raise GentleREST::ResourceNotFoundError,
          "Template not found: #{name.inspect}"
      end
      
      # Normalize to symbol
      type = File.extname(path).gsub(/^\./, "").to_s.to_sym
      if !self.types.include?(type)
        raise ArgumentError,
          "Unrecognized template type: #{type.inspect}\n" +
          "Valid types: " +
          "#{(self.class.types.map {|t| t.inspect}).join(", ")}"
      end
      raw_content = File.open(path, "r") do |file|
        file.read
      end
      
      # Add template methods to Context.
      if !context.kind_of?(GentleREST::Context)
        context = GentleREST::Context.new(context, :capture_output => false)
      end
      (class <<context; self; end).send(:define_method, :inner_content) do
        GentleREST::Template.render(
          options[:inner_template], options[:inner_context])
      end
      (class <<context; self; end).send(:define_method, :preformat) do |x|
        "<pre>" + x.gsub("\n", "&#x000A;") + "</pre>"
      end
      (class <<context; self; end).send(:define_method, :h) do |text|
        if !text.kind_of?(String)
          if text.respond_to?(:to_str)
            text = text.to_str
          else
            text = test.to_s
          end
        end
        text.gsub(/\</, "&lt;")
      end
      
      begin
        return self.processor(type).call(raw_content, context)
      rescue Exception => e
        e.message << "\nError occurred while rendering '#{name}'"
        raise e
      end
    end
  end
end

GentleREST::Template.register_type(:haml) do |input, context|
  Haml::Engine.new(
    input, {
      :attr_wrapper => "\""
    }
  ).render(context)
end

GentleREST::Template.register_type(:sass) do |input, context|
  Sass::Engine.new(
    input, {
      :style => :expanded,
      :load_paths => $TEMPLATE_PATH
    }
  ).render
end
