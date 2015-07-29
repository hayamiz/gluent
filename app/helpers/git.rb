
module Gluent

module GitHelper
  def run_git(*cmd)
    cmd = ["git", *cmd]
    stdout = nil
    status = nil

    Dir.chdir($gluent_data_dir) do
      begin
        status = IO.popen(cmd, "r") do |io|
          stdout = io.read
          io.close
          $?
        end
      rescue Errno::ENOENT
        status = nil
      end
    end

    if status.nil? || status.exitstatus != 0
      halt "Failed to run: #{cmd.join(' ')}"
    end

    stdout
  end

  def try_git(*cmd)
    cmd = ["git", *cmd]
    stdout = nil
    status = nil

    begin
      status = IO.popen(cmd, "r") do |io|
        stdout = io.read
        io.close
        $?
      end
    rescue Errno::ENOENT
      status = nil
    end

    if status.nil? || status.exitstatus != 0
      return false
    end
    return true
  end

  def git_status(filepath)
    stdout = run_git "status", "--porcelain", "--", filepath
    stdout.each_line do |line|
      if line.include?(filepath)
        return line.split[0]
      end
    end

    nil
  end

  def git()
    if $git_base.nil?
      Dir.chdir($gluent_data_dir) do
        $git_base = Git.open(".", :log => ::Logger.new(STDERR))
      end
    end

    $git_base
  end

  def git_log(filepath)
    git.log.path(filepath)
  end

  def git_commit(filepath)
  end

  def available_filepath(orig_filename, mime_type)
    orig_filename = File.basename(orig_filename)

    unless File.exists?(File.expand_path(orig_filename, $gluent_data_dir))
      return File.expand_path(orig_filename, $gluent_data_dir)
    end

    ext = nil

    if orig_filename =~ /\.([a-zA-Z0-9]+)$/
      ext = "." + $~[1]
    else
      case mime_type
      when "image/gif"
        ext = ".gif"
      when "image/png"
        ext = ".png"
      when "image/jpeg"
        ext = ".jpg"
      else
        ext = ""
      end
    end

    base = File.basename(orig_filename, ext)

    idx = 1
    while true
      path = File.expand_path(sprintf("%s_%d%s", base, idx, ext), $gluent_data_dir)
      unless File.exists?(path)
        return path
      end

      idx += 1
    end
  end

  def diff_pretty_print(patch)
    patch = patch.gsub(/^(diff.*)$/, "<span class=\"diff-metadata\">\\1</span>")
    patch = patch.gsub(/^(index.*)$/, "<span class=\"diff-metadata\">\\1</span>")
    patch = patch.gsub(/^(deleted.*)$/, "<span class=\"diff-metadata\">\\1</span>")
    patch = patch.gsub(/^(Binary.*)$/, "<span class=\"diff-metadata\">\\1</span>")
    patch = patch.gsub(/^(@@.*)$/, "<span class=\"diff-metadata\">\\1</span>")

    patch = patch.gsub(/^(\+.*)$/, "<span class=\"add-line\">\\1</span>")
    patch = patch.gsub(/^(-.*)$/, "<span class=\"del-line\">\\1</span>")
  end

  def commit_diff(commit, path = nil)
    empty = git.gcommit("4b825dc642cb6eb9a060e54bf8d69288fbee4904")

    if commit.parent
      diff = commit.parent.diff(commit)
    else
      diff = empty.diff(commit)
    end

    if path
      diff = diff.path(path)
    end

    diff
  end
end

end # Gluent
