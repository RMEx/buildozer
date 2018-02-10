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

  CopyFile = Win32API.new('kernel32', 'CopyFile', 'PPI', 'I')

  extend self

  def write(file, str, flag = "w+")
    File.open(file, flag) {|f| f.write(str)}
  end

  def read(file)
    File.open(file, 'r') { |f| f.read }
  end

  def copy(src, dst)
    k = read(src)
    write(dst, k)
  end

  def overkill_copy(src, dst)
    CopyFile.call(src,dst,0)
  end

  def move(src, dst)
    copy(src, dst)
    File.delete(src)
  end

  def safe_rmdir(d, v=false)
    if Dir.exist?(d)
      begin delete_all(d)
      rescue Errno::ENOTEMPTY
      end
    end
  end

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

  def safe_mkdir(d)
    unless Dir.exist?(d)
      Dir.mkdir(d)
    end
  end

  def eval_file(f)
    return eval(read(f))
  end

  def remove_recursive(dir, verbose=false)
    return unless Dir.exist?(dir)
    d = Dir.glob(dir + '/*')
    if d.length > 0
      d.each do |entry|
        if File.directory?(entry)
          remove_recursive(entry)
        else
          File.delete(entry)
          puts "Suppress #{entry}" if verbose
        end
      end
    else
      begin
        Dir.rmdir(dir)
        puts "Suppress #{dir}" if verbose
      rescue Errno::ENOTEMPTY
      end
    end
    begin
      Dir.rmdir(dir)
      puts "Suppress #{dir}" if verbose
    rescue Errno::ENOTEMPTY
    end
  end
end

module Externalizer
  extend self
  def run
    open_rvdata2
    externalize
  end

  def open_rvdata2
    @scripts = load_data 'Data/Scripts.rvdata2'
    n = 1
    @scripts.each do |script|
      script[2] = Zlib::Inflate.inflate script[2]
      script[2] = script[2].split("\r").join("")
      if script[1] == "" && script[2] != ""
        script[1] = "untitled (#{n})"
        n += 1
      end
    end
  end
  
  def externalize
    @dir = ['Scripts']
    FileTools.safe_rmdir @dir[0]
    Dir.mkdir @dir[0]
    @scripts.each {|s| externalize_script(s)}
  end

  def externalize_script(s)
    return if is_category? s
    return if s[2] == ""
    write_script(s)
  end

  def is_category?(s)
    if s[1].include?('▼')
      @dir = [@dir[0]] << s[1].delete('▼').strip
    elsif s[1].include?('■')
      eval_depth(s[1])
      @dir << s[1].delete('■').strip
    else
      return false
    end
    Dir.mkdir @dir.join "/"
    return true
  end

  def eval_depth(name)
    depth = (name.length - name.lstrip.length) / 3 + 2
    if depth < @dir.length
      (@dir.length - depth).times {@dir.pop}
    end
  end

  def write_script(s)
    eval_depth(s[1])
    s[1].strip!
    FileTools.write("#{@dir.join("/")}/#{s[1]}.rb", s[2])
  end

end

Externalizer.run