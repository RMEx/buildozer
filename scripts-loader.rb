# -*- coding: utf-8 -*-
#==============================================================================
# ** scripts-loader v1.1.0
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/scripts-externalizer
#------------------------------------------------------------------------------
# Load all scripts from the given folder
# See the README.md on GitHub! 
#==============================================================================

#==============================================================================
# ** CONFIGURATION
#==============================================================================

module XT_CONFIG

  LOAD_FROM = "Scripts"  # Load the scripts from the folder you want.
                         # Can be "C:/.../MyScripts/" or "../../MyScripts/"
end

#==============================================================================
# ** Loader
#------------------------------------------------------------------------------
#  Load all scripts
#==============================================================================

module Loader 
  #--------------------------------------------------------------------------
  # * Extend self
  #--------------------------------------------------------------------------
  extend self
  #--------------------------------------------------------------------------
  # * Run the loader
  #--------------------------------------------------------------------------
  def run
    identifyType() 
    read_list(XT_CONFIG::LOAD_FROM + "/")
  end
  #--------------------------------------------------------------------------
  # * Read a file
  #--------------------------------------------------------------------------
  def read(file)
    File.open(file, 'r') { |f| f.read }
  end
  #--------------------------------------------------------------------------
  # * Read a list and load all the elements
  #--------------------------------------------------------------------------
  def read_list(path)
    @list = read(path + "_list.rb").split("\n")
    @list.each do |e|
      e.strip!
      next if e[0] == 35 || e[0] == "#"
      if e[-1] == 103 || e[-1] == "/"
        read_list(path + e) if @scriptType == "rv2"
        #rpg maker xp dont suport sub folder of scripts
        return if @scriptType == "error" || @scriptType == "rx" 
      else
        Kernel.send(:load, Dir.pwd + "/" + path + e + ".rb")
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Identify type of script
  #--------------------------------------------------------------------------
  def identifyType()
    Dir.foreach(Dir.pwd + "\\Data") {|x|
      if x == "Scripts.rxdata"
        @scriptType = "rx"
        return
      elsif x =="Scripts.rvdata2"
        @scriptType = "rv2"
        return
      end
    }
    @scriptType = "error" #error, no type suported
  end
end

Loader.run