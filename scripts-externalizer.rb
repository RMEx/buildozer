# -*- coding: utf-8 -*-
#==============================================================================
# ** scripts-externalizer v1.1.0
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/scripts-externalizer
#------------------------------------------------------------------------------
# Externalize all scripts from "Data/Scripts.rvdata2" to the given folder
# See the README.md on GitHub!
#==============================================================================

#==============================================================================
# ** CONFIGURATION
#==============================================================================

module XT_CONFIG

  EXTRACT_TO = "Scripts"  # Extracts the scripts to the folder you want.
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
# ** Externalizer
#------------------------------------------------------------------------------
#  Externalize all scripts
#==============================================================================

module Externalizer
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
  # * Get the name of the game from Game.ini
  #--------------------------------------------------------------------------
  key = 'Title'
  buffer = [].pack('x256')
  GetPrivateProfileString = Win32API.new('kernel32', 'GetPrivateProfileString', 'ppppip', 'i')
  l = GetPrivateProfileString.call(section, key, nil, buffer, buffer.size, filename)
  NAME = buffer[0, l]
  #--------------------------------------------------------------------------
  # * Run externalization
  #--------------------------------------------------------------------------
  def run
    identifyType
    open_rvdata2
    return if cancel
    return if allready_externalized
    return if folder_exist
    externalize
    rewrite_rvdata2
    the_end
    exit
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def open_rvdata2
    @scripts = load_data SCRIPTS
    n = 1
    @scripts.each do |script|
      script[2] = Zlib::Inflate.inflate script[2]
      @ignored = script if script[2].include?("# ** scripts-externalizer")
      script[2] = script[2].split("\r")
      if script[2][0] && script[2][0] != "# -*- coding: utf-8 -*-"
        script[2] = script[2].insert(0, "# -*- coding: utf-8 -*-\n")
      end
      script[2] = script[2].join("")
      if script[1] == "" && script[2] != ""
        script[1] = "untitled (#{n})"
        n += 1
      end
    end
    @scripts.delete(@ignored) if @ignored
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def cancel
    msg = "Externalize all scripts to \"#{XT_CONFIG::EXTRACT_TO}\"?

 (a backup for \"#{SCRIPTS}\" will be created)"
    cp = Prompt.yes_no_cancel?("scripts-externalizer", msg)
    if cp != :yes
      return true
    end
    false
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def allready_externalized
    if @scripts.length == 1
      msgbox "Scripts are allready externalized... operation canceled." if @scriptType == "rv2"
      print "Scripts are allready externalized... operation canceled." if scriptType == "rx"
      return true
    end
    false
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def folder_exist
    dir = XT_CONFIG::EXTRACT_TO.gsub(/\//, '\\')
    if File.directory?(dir)
      msg = "The folder \"#{dir}\" allready exist, do you want to overwrite it?"
      cp = Prompt.yes_no_cancel?(NAME, msg)
      if cp == :yes
        FileTools.rmdir dir
        Graphics.update while File.directory?(dir)
      else
        return true
      end
    end
    system("mkdir #{dir}")
    Graphics.update until File.directory?(dir)
    false
  end
  #--------------------------------------------------------------------------
  # * Externalize the scripts
  #--------------------------------------------------------------------------
  def externalize
    @dir = [XT_CONFIG::EXTRACT_TO]
    @list = Hash.new
    @count = Hash.new
    @scripts.each {|s| externalize_script(s)}
    @list.each do |path, list|
      FileTools.write(path + "/_list.rb", list.join("\n"))
    end
    FileTools.write(XT_CONFIG::EXTRACT_TO + "/scripts-loader.rb", scripts_loader)
  end
  #--------------------------------------------------------------------------
  # * Externalize one script
  #--------------------------------------------------------------------------
  def externalize_script(s)
    return if is_category? s
    return if s[2] == ""
    write_script(s)
  end
  #--------------------------------------------------------------------------
  # * Check if the script is a category
  #--------------------------------------------------------------------------
  def is_category?(s)
    if s[1].include?('▼')
      s[1] = s[1].delete('▼').strip
      @dir = [@dir[0]]
      add_category(@dir[0], s[1])
    elsif s[1].include?('■')
      eval_depth(s[1])
      s[1] = s[1].delete('■').strip
      add_category(@dir.join("/"), s[1])
    else
      return false
    end
    Dir.mkdir(@dir.join("/"))
    if s[2] != ""
      s[1] = " " * ((@dir.length - 2) * 3) + s[1]
      write_script(s)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # * Add a category into the list
  #--------------------------------------------------------------------------
  def add_category(path, name)
    @list[path] ||= []
    if @list[path].include?(name + "/")
      @count[path + name + "/"] ||= 1
      @count[path + name + "/"] += 1
      name = name + " (#{@count[path + name + "/"]})"
    end
    @list[path] << name + "/"
    @dir << name
  end
  #--------------------------------------------------------------------------
  # * Add a script into the list
  #--------------------------------------------------------------------------
  def add_script(path, name)
    @list[path] ||= []
    if @list[path].include?(name)
      @count[path + name] ||= 1
      @count[path + name] += 1
      name = name + " (#{@count[path + name]})"
    end
    @list[path] << name
    name
  end
  #--------------------------------------------------------------------------
  # * Eval the depth of the script or repertory (tree)
  #--------------------------------------------------------------------------
  def eval_depth(name)
    depth = (name.length - name.lstrip.length) / 3 + 2
    if depth < @dir.length
      (@dir.length - depth).times {@dir.pop}
    end
  end
  #--------------------------------------------------------------------------
  # * Write a script file (.rb)
  #--------------------------------------------------------------------------
  def write_script(s)
    eval_depth(s[1])
    name = s[1].strip
    path = @dir.join "/"
    name = add_script(path, name)
    FileTools.write(path + "/" + name + ".rb", s[2])
  end
  #--------------------------------------------------------------------------
  # * Rewrite the rvdata2
  #--------------------------------------------------------------------------
  def rewrite_rvdata2
    time = Time.now.strftime("%y%m%d-%H%M%S")
    new_name = SCRIPTS.split('.').insert(1, "_backup-#{time}.").join('')
    FileTools.copy(SCRIPTS, new_name)
    new_rvdata = [
      [
        0, "Load scripts",
        deflate("Kernel.send(:load, '#{XT_CONFIG::EXTRACT_TO}/scripts-loader.rb')")
      ]
    ]
    save_data(new_rvdata, SCRIPTS)
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
      if @scriptType == "rv2"
        data_system = load_data("Data/System.rvdata2")
        data_system.battle_end_me.play
      end
    rescue
    end
    messageText = "All scripts externalized to \"#{XT_CONFIG::EXTRACT_TO}\" folder! \\o/

Now CLOSE AND OPEN THE PROJECT and enjoy your scripts! :)

Thanks you for using this script! <3

BilouMaster Joke"
    if @scriptType == "rx"
      print messageText +" and Gustavo Sasaki"
      return
    end
    msgbox messageText
  end
  #--------------------------------------------------------------------------
  # * Epic string script
  #--------------------------------------------------------------------------
  def scripts_loader
"# -*- coding: utf-8 -*-
#==============================================================================
# ** ORMS Converter v1.1.0
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/scripts-externalizer
#------------------------------------------------------------------------------
# Loads all scripts in the Scripts folder
#
# To add a script: create a newscript.rb in the folder, and add his name
# in the _list.rb
#
# To add a folder: create a new folder, add the name of the folder in _list.rb
# with a \"/\" to the end of the name, create a new _list.rb in the folder
#==============================================================================

module XT_CONFIG
  #==============================================================================
  # ** CONFIGURATION
  #==============================================================================

  LOAD_FROM = \"#{XT_CONFIG::EXTRACT_TO}\"  # Load the scripts from the folder you want.
                           # Can be \"C:/.../MyScripts/\" or \"../../MyScripts/\"

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
    read_list(XT_CONFIG::LOAD_FROM + \"/\")
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
    @list = read(path + \"_list.rb\").split(\"\\n\")
    @list.each do |e|
      e.strip!
      next if e[0] == \"#\"
      if e[-1] == \"/\"
        read_list(path + e)
      else
        Kernel.send(:load, path + e + \".rb\")
      end
    end
  end
end

Loader.run"
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

Externalizer.run