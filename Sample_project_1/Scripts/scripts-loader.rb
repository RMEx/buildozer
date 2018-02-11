# -*- coding: utf-8 -*-
#==============================================================================
# ** ORMS Converter
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/OLD_RM_STYLE
#------------------------------------------------------------------------------
# Loads all scripts in the Scripts folder
#
# To add a script: create a newscript.rb in the folder, and add his name
# in the _list.rb
#
# To add a folder: create a new folder, add the name of the folder in _list.rb
# with a "/" to the end of the name, create a new _list.rb in the folder
#==============================================================================

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
    read_list("Scripts/")
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
      next if e[0] == "#"
      if e[-1] == "/"
        read_list(path + e)
      else
        Kernel.send(:load, path + e + ".rb")
      end
    end
  end
end

Loader.run