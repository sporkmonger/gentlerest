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

require "rubygems"
require "gentlerest"

module GentleREST
  # The Locator module is responsible for tracking the locations of
  # certain files and directories within a GentleREST application.
  module Locator
    # This method locates a particular named file or resource within
    # the current GentleREST application.
    #
    # The following keys are recognized:
    #
    # * :root
    # * :config
    # * :lib
    # * :vendor
    # * :templates
    # * :init_script
    def self.locate(key)
      if !defined?(@locations) || @locations == nil
        @locations = {}
      end
      if @locations[key] == nil
        method = "locate_#{key.to_s}".to_sym
        if self.respond_to?(method)
          @locations[key] = self.send(method)
        else
          raise ArgumentError, "Unrecognized location key."
        end
      end
      return @locations[key]
    end
    
  protected
    # Finds the root directory of the current GentleREST application.
    def self.locate_root
      root = ENV['GENTLE_ROOT']
      if root == nil
        current_directory = File.expand_path(".")
        loop do
          if File.exist?(File.join(current_directory, "config")) && 
              (File.exist?(File.join(current_directory, "rakefile")) ||
              File.exist?(File.join(current_directory, "Rakefile")))
            root = current_directory
            break
          elsif current_directory == "/" || current_directory ==
              File.expand_path(File.join(current_directory, ".."))
            # Top level, nothing found.
            break
          else
            current_directory = File.expand_path(
              File.join(current_directory, "..")
            )
          end
        end
      end
      return root if root && File.exist?(root)
      return nil
    end

    # Finds the config directory of the current GentleREST application.
    def self.locate_config
      root = self.locate(:root)
      config = nil
      if root != nil
        config = File.expand_path(File.join(root, "/config"))
      end
      return config if config && File.exist?(config)
      return nil
    end

    # Finds the lib directory of the current GentleREST application.
    def self.locate_lib
      root = self.locate(:root)
      lib = nil
      if root != nil
        lib = File.expand_path(File.join(root, "/lib"))
      end
      return lib if lib && File.exist?(lib)
      return nil
    end

    # Finds the templates directory of the current GentleREST application.
    def self.locate_templates
      root = self.locate(:root)
      templates = nil
      if root != nil
        templates = File.expand_path(File.join(root, "/templates"))
      end
      return templates if templates && File.exist?(templates)
      return nil
    end

    # Finds the vendor directory of the current GentleREST application.
    def self.locate_vendor
      root = self.locate(:root)
      vendor = nil
      if root != nil
        vendor = File.expand_path(File.join(root, "/vendor"))
      end
      return vendor if vendor && File.exist?(vendor)
      return nil
    end
    
    # Finds the init script for the current GentleREST application.
    def self.locate_init_script
      root = self.locate(:root)
      init_script = nil
      
      # Hunt down the init script.  It can either be in the GENTLE_ROOT
      # directory or in GENTLE_ROOT/config.
      if ENV['INIT_SCRIPT'] == nil
        init_script = File.expand_path(
          File.join(root, "/config/init.rb")
        )
        if !File.exist?(init_script)
          init_scripts = Dir.glob(File.expand_path(
            File.join(root, "/config/*.init.rb")
          ))
          if init_scripts.size == 1
            init_script = init_scripts.first
          elsif init_scripts.size > 1
            # Multiple named init scripts found, could not select.
            return nil
          end
        end
        if !File.exist?(init_script)
          init_script = File.expand_path(
            File.join(root, "config.ru")
          )
        end
      else
        named_init_script = ENV['INIT_SCRIPT']
        if File.exist?(File.expand_path(named_init_script))
          init_script = File.expand_path(named_init_script)
        else
          init_script = File.expand_path(
            File.join(root, "/config/", named_init_script)
          )
          if !File.exist?(init_script)
            init_script = File.expand_path(
              File.join(root, "/config/", named_init_script.to_s + ".init.rb")
            )
          end
        end
      end
      
      return init_script if init_script && File.exist?(init_script)
      return nil
    end
  end
end
