# -*- coding: utf-8 -*-
#==============================================================================
# ** scripts-compiler v1.1.0
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/scripts-externalizer
#------------------------------------------------------------------------------
# Compile scripts from the given folder to "Scripts.rvdata2", in the same place
# as this one. See the README.md on GitHub!
#==============================================================================

#==============================================================================
# ** CONFIGURATION
#==============================================================================

module XT_CONFIG

  COMPILE_FROM = "Scripts"  # Compile the scripts from the folder you want.
                            # Can be "C:/.../MyScripts/" or "../../MyScripts/"
end

#==============================================================================
# ** FileTools
#------------------------------------------------------------------------------
#  Tools for file manipulation
#==============================================================================

module FileTools
  #--------------------------------------------------------------------------
  # * Extend self
  #--------------------------------------------------------------------------
  extend self
  #--------------------------------------------------------------------------
  # * Win32API
  #--------------------------------------------------------------------------
  CopyFile = Win32API.new('kernel32', 'CopyFile', 'PPI', 'I')
  #--------------------------------------------------------------------------
  # * Write a file
  #--------------------------------------------------------------------------
  def write(file, str, flag = "w+")
    File.open(file, flag) {|f| f.write(str)}
  end
  #--------------------------------------------------------------------------
  # * Read a file
  #--------------------------------------------------------------------------
  def read(file)
    File.open(file, 'r') { |f| f.read }
  end
  #--------------------------------------------------------------------------
  # * Copy a file
  #--------------------------------------------------------------------------
  def copy(src, dst)
    CopyFile.call(src,dst,0)
  end
  #--------------------------------------------------------------------------
  # * Create a folder
  #--------------------------------------------------------------------------
  def mkdir(d)
    unless File.directory?(d)
      Dir.mkdir(d)
    end
  end
  #--------------------------------------------------------------------------
  # * Remove a folder
  #--------------------------------------------------------------------------
  def rmdir(d, v=false)
    if File.directory?(d)
      begin delete_all(d)
      rescue Errno::ENOTEMPTY
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Delete all folders
  #--------------------------------------------------------------------------
  def delete_all(dir)
    Dir.foreach(dir) do |e|
      next if [".",".."].include? e
      fullname = dir + File::Separator + e
      if FileTest::directory?(fullname)
        delete_all(fullname)
      else
        File.delete(fullname)
      end
    end
    Dir.delete(dir)
  end
end

#==============================================================================
# ** Prompt
#------------------------------------------------------------------------------
#  Display prompt
#==============================================================================

module Prompt
  #--------------------------------------------------------------------------
  # * Extend self
  #--------------------------------------------------------------------------
  extend self
  #--------------------------------------------------------------------------
  # * Win32API
  #--------------------------------------------------------------------------
  FindWindow = Win32API.new('user32', 'FindWindow', 'pp', 'i')
  MessageBox = Win32API.new('user32','MessageBox','lppl','i')
  HWND = FindWindow.call('RGSS Player', 0)
  #--------------------------------------------------------------------------
  # * Yes no
  #--------------------------------------------------------------------------
  def yes_no?(title, message)
    k = MessageBox.call(HWND, message, title, 305)
    k == 1
  end
  #--------------------------------------------------------------------------
  # * Yes no cancel
  #--------------------------------------------------------------------------
  def yes_no_cancel?(title, message)
    k = MessageBox.call(HWND, message, title, 3)
    return :yes if k == 6
    return :no if k == 7
    :cancel
  end
end

#==============================================================================
# ** Compiler
#------------------------------------------------------------------------------
#  Compile scripts from the "Scripts" folder, to the "Scripts.rvdata2"
#==============================================================================

module Compiler
  #--------------------------------------------------------------------------
  # * Extend self
  #--------------------------------------------------------------------------
  extend self
  #--------------------------------------------------------------------------
  # * Get Scripts.rvdata2 path from Game.ini
  #--------------------------------------------------------------------------
  filename = './Game.ini'
  section = 'Game'
  key = 'Scripts'
  buffer = [].pack('x256')
  GetPrivateProfileString = Win32API.new('kernel32', 'GetPrivateProfileString', 'ppppip', 'i')
  l = GetPrivateProfileString.call(section, key, nil, buffer, buffer.size, filename)
  SCRIPTS = buffer[0, l]
  #--------------------------------------------------------------------------
  # * Run the compiler
  #--------------------------------------------------------------------------
  def run
    identifyType()
    return if cancel
    return if no_scripts
    @target = []
    open_rvdata2
    read_list(XT_CONFIG::COMPILE_FROM + "/")
    rewrite_rvdata2
    the_end()
    exit
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def cancel
    msg = "Compile scripts from the folder \"#{XT_CONFIG::COMPILE_FROM}\" in \"#{SCRIPTS}\"?

 (a backup for \"#{SCRIPTS}\" will be created)"
    cp = Prompt.yes_no_cancel?("scripts-compiler", msg)
    if cp != :yes
      return true
    end
    false
  end
  #--------------------------------------------------------------------------
  # * If the "Scripts" folder doesn't exists
  #--------------------------------------------------------------------------
  def no_scripts
    if !File.directory?("#{XT_CONFIG::COMPILE_FROM}")
      msgbox "Cannot find \"#{XT_CONFIG::COMPILE_FROM}\"" if @scriptType == "rv2"
      print "Cannot find \"#{XT_CONFIG::COMPILE_FROM}\"" if @scriptType == "rx"
      return true
    end
    false
  end  
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def open_rvdata2
    @depth = 1
    @scripts = load_data SCRIPTS
    @scripts.each_with_index do |script, i|
      @depth = 2 if script[1] == "▼ Modules"
      script[2] = Zlib::Inflate.inflate script[2]
      if @scriptType == "rv2"
        @target = i if script[2].include?("# ** scripts-compiler") ||
        script[2].include?("Kernel.send(:load, '#{XT_CONFIG::COMPILE_FROM}/scripts-loader.rb')")
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Read a list and add all the elements
  #--------------------------------------------------------------------------
  def read_list(path)
    @list = FileTools.read(path + "_list.rb").split("\n")
    @list.each do |e|
      e.strip!
      next if e[0] == 35 || e[0] == "#"
      if  e[-1] == 103 || e[-1] == "/"
        next if @scriptType == "rx"
        @depth += 1
        add_category(e)
        read_list(path + e)
        @depth -= 1
      else
        file = FileTools.read(path + e + ".rb")
        position =remove_old_scripts(e)

        add_script(e, file, position) if @scriptType == "rx"
        add_scriptRv2(e,file) if @scriptType == "rv2"
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Add a category
  #--------------------------------------------------------------------------
  def add_category(name)
    name = name.clone.delete "/"
    if @depth == 2
      name.insert(0, '▼ ')
      add_scriptRv2("", "")
      add_scriptRv2(name, "")
    else
      @depth -= 1
      name.insert(0, '■ ')
      add_scriptRv2(name, "")
      @depth += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Add a script
  #--------------------------------------------------------------------------
  def add_script(name, content,position)
    name.insert(0, " " * [(@depth - 2) * 3, 0].max) unless name == ""
    content = content.split("\n")
    if content.is_a?(Array)
      content.delete("# -*- coding: utf-8 -*-")
      content = content.join("\n")
    end

    @scripts.insert(position, [0, name, content])
  end
  #--------------------------------------------------------------------------
  # * Add a script for rvdata2 script
  #--------------------------------------------------------------------------
  def add_scriptRv2(name, content)
    add_script(name, content,@target)
    @target += 1
  end
  #--------------------------------------------------------------------------
  # * Rewrite the rvdata2
  #--------------------------------------------------------------------------
  def rewrite_rvdata2
    time = Time.now.strftime("%y%m%d-%H%M%S")
    new_name = SCRIPTS.split('.').insert(1, "backup-#{time}.").join('')
    FileTools.copy(SCRIPTS, new_name)
    @scripts.delete_if do |s|
      (s == nil) ||
      s[2].include?("# ** scripts-externalizer") ||
      s[2].include?("# ** scripts-loader") ||
      s[2].include?("# ** scripts-compiler")|| 
      (s[1] == "")
    end

    @scripts.each {|s| 
    s[2] = deflate(s[2])}
    save_data(@scripts, SCRIPTS)
  end
  #--------------------------------------------------------------------------
  # * Compress the content
  #--------------------------------------------------------------------------
  def deflate(content)
    docker  = Zlib::Deflate.new(Zlib::BEST_COMPRESSION)
    data    = docker.deflate(content, Zlib::FINISH)
    docker.close
    data
  end
  #--------------------------------------------------------------------------
  # * Epic END
  #--------------------------------------------------------------------------
  def the_end()
    begin
      if @scriptType == "rv2"
        data_system = load_data("Data/System.rvdata2")
        data_system.battle_end_me.play
      end
    rescue
    end
    messageText = "All scripts compiled into \"#{SCRIPTS}\"! \\o/
    Now CLOSE AND OPEN THE PROJECT and enjoy your scripts! :)
    
    And I leave you the responsibility to delete \"#{XT_CONFIG::COMPILE_FROM}\" which is supposed to no longer serve!
    
    Thanks you for using this script! <3
    
    BilouMaster Joke"
    if @scriptType == "rx"
      print messageText +" and Gustavo Sasaki"
      return
    end
    msgbox messageText
  end
  #--------------------------------------------------------------------------
  # * Remove old version of the script that will be compiled and retuned his index
  #--------------------------------------------------------------------------
  def remove_old_scripts(e)
    i=-1
    index = -1
    @scripts.delete_if do |s|
      i+=1
      if(s != nil) && (e == s[1])
          index = i
      end
      (s == nil) ||
      s[2].include?("# ** scripts-externalizer") ||
      s[2].include?("# ** scripts-loader") ||
      s[2].include?("# ** scripts-compiler")|| 
      (e == s[1])
    end
    return index
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

Compiler.run