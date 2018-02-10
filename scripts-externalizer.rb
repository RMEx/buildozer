# -*- coding: utf-8 -*-
#==============================================================================
# ** ORMS Converter
#------------------------------------------------------------------------------
# By Joke @biloumaster <joke@biloucorp.com>
# GitHub: https://github.com/RMEx/OLD_RM_STYLE
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
  def safe_mkdir(d)
    unless Dir.exist?(d)
      Dir.mkdir(d)
    end
  end
  #--------------------------------------------------------------------------
  # * Remove a folder
  #--------------------------------------------------------------------------
  def safe_rmdir(d, v=false)
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
  #--------------------------------------------------------------------------
  # * Eval a file
  #--------------------------------------------------------------------------
  def eval_file(f)
    return eval(read(f))
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
  # * Run externalization
  #--------------------------------------------------------------------------
  def run
    open_rvdata2
    externalize
    rewrite_rvdata2
    p "ok"
  end
  #--------------------------------------------------------------------------
  # * Open Scripts.rvdata2
  #--------------------------------------------------------------------------
  def open_rvdata2
    @scripts = load_data 'Data/Scripts.rvdata2'
    n = 1
    @scripts.each do |script|
      p script[0]
      script[2] = Zlib::Inflate.inflate script[2]
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
  end
  #--------------------------------------------------------------------------
  # * Externalize the scripts
  #--------------------------------------------------------------------------
  def externalize
    @dir = ['Scripts']
    @list = Hash.new
    msg = "The folder \"Scripts\" allready exist, do you want to overwrite it?"
    cp = Prompt.yes_no_cancel?("Externalization", msg)
    if cp == :yes
      FileTools.safe_rmdir @dir[0]
      Graphics.update while Dir.exist?(@dir[0])
      Dir.mkdir @dir[0]
      @scripts.each {|s| externalize_script(s)}
    end
    @list.each do |path, list|
      list.map! {|n| '"' + n + '"'}
      FileTools.write(path + "/_list.rb", list.join(",\n"))
    end
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
      name = s[1].delete('▼').strip
      @dir = [@dir[0]]
      add_category(@dir[0], name)
    elsif s[1].include?('■')
      eval_depth(s[1])
      name = s[1].delete('■').strip
      add_category(@dir.join("/"), name)
    else
      return false
    end
    Dir.mkdir @dir.join "/"
    return true
  end
  #--------------------------------------------------------------------------
  # * Add a category into the list
  #--------------------------------------------------------------------------
  def add_category(path, name)
    @list[path] ||= []
    if (nb = @list[path].count(name + "/")) > 0
      name = name + " (#{nb + 1})"
    end
    @list[path] << name + "/"
    @dir << name
  end
  #--------------------------------------------------------------------------
  # * Add a script into the list
  #--------------------------------------------------------------------------
  def add_script(path, name)
    @list[path] ||= []
    if (nb = @list[path].count(name)) > 0
      name = name + " (#{nb + 1})"
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
    FileTools.copy("Data/Scripts.rvdata2", "Data/Scripts_backup-#{time}.rvdata2")
    new_rvdata = [
      [
        0, "scripts-loader",
        deflate("Kernel.send(:load, 'Scripts/scripts-loader')")
      ]
    ]
    save_data(new_rvdata, "Data/Scripts.rvdata2")
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

end

Externalizer.run