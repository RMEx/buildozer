# -*- coding: utf-8 -*-
#==============================================================================
# ** scripts-compiler
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/scripts-externalizer
#------------------------------------------------------------------------------
# Compile scripts from the "Scripts" folder, to the "Scripts.rvdata2"
# Scripts will be added in the same place you put this script
#==============================================================================

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
    unless Dir.exist?(d)
      Dir.mkdir(d)
    end
  end
  #--------------------------------------------------------------------------
  # * Remove a folder
  #--------------------------------------------------------------------------
  def rmdir(d, v=false)
    if Dir.exist?(d)
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
  # * Run the compiler
  #--------------------------------------------------------------------------
  def run
    return if cancel
    return if no_scripts
    open_rvdata2
    read_list("Scripts/")
    rewrite_rvdata2
    the_end
    exit
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def cancel
    msg = "Compile scripts from the folder \"Scripts\" in the \"Scripts.rvdata2\"?

 (a backup for \"Scripts.rvdata2\" will be created in the \"Data\" folder)"
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
    if !Dir.exist?("Scripts")
      msgbox "Cannot find the \"Scripts\" folder"
      return true
    end
    false
  end  
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def open_rvdata2
    @depth = 1
    @scripts = load_data 'Data/Scripts.rvdata2'
    @scripts.each_with_index do |script, i|
      @depth = 2 if script[1] == "▼ Modules"
      script[2] = Zlib::Inflate.inflate script[2]
      @target = i if script[2].include?("# ** scripts-compiler") ||
        script[2].include?("Kernel.send(:load, 'Scripts/scripts-loader.rb')")
    end
  end
  #--------------------------------------------------------------------------
  # * Read a list and add all the elements
  #--------------------------------------------------------------------------
  def read_list(path)
    @list = FileTools.read(path + "_list.rb").split("\n")
    @list.each do |e|
      e.strip!
      next if e[0] == "#"
      if e[-1] == "/"
        @depth += 1
        add_category(e)
        read_list(path + e)
        @depth -= 1
      else
        file = FileTools.read(path + e + ".rb")
        add_script(e, file)
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
      add_script("", "")
      add_script(name, "")
    else
      @depth -= 1
      name.insert(0, '■ ')
      add_script(name, "")
      @depth += 1
    end
  end
  #--------------------------------------------------------------------------
  # * Add a script
  #--------------------------------------------------------------------------
  def add_script(name, content)
    name.insert(0, " " * [(@depth - 2) * 3, 0].max) unless name == ""
    content = content.split("\n")
    if content.is_a?(Array)
      content.delete("# -*- coding: utf-8 -*-")
      content = content.join("\n")
    end
    @scripts.insert(@target, [0, name, content])
    @target += 1
  end
  #--------------------------------------------------------------------------
  # * Rewrite the rvdata2
  #--------------------------------------------------------------------------
  def rewrite_rvdata2
    time = Time.now.strftime("%y%m%d-%H%M%S")
    FileTools.copy("Data/Scripts.rvdata2", "Data/Scripts_backup-#{time}.rvdata2")
    @scripts.delete_if do |s|
      s[2].include?("# ** scripts-externalizer") ||
      s[2].include?("# ** scripts-loader") ||
      s[2].include?("# ** scripts-compiler")
    end
    @scripts.each {|s| s[2] = deflate(s[2])}
    save_data(@scripts, "Data/Scripts.rvdata2")
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
  def the_end
    begin
      data_system = load_data("Data/System.rvdata2")
      data_system.battle_end_me.play
    rescue
    end
    msgbox "All scripts compiled into \"Scripts.rvdata2\"! \\o/

Now close and open the project again and enjoy your scripts! :)

And I leave you the responsibility to delete the \"Scripts\" folder which is supposed to no longer serve!

Thanks you for using this script! <3

BilouMaster Joke"
  end
end

Compiler.run