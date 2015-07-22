
module Gluent

class Entry
  class << self
    include GitHelper
    include RenderHelper

    def all
      Dir.chdir($gluent_data_dir) do
        Dir.glob("**/*.md").sort_by do |path|
          - File::Stat.new(path).mtime.to_f
        end.map do |path|
          find(path)
        end
      end
    end

    def find(path, commit = nil)
      content = nil
      mtime = nil
      Dir.chdir($gluent_data_dir) do
        if commit
          content = git.object("#{commit}:#{path}").contents
        else
          content = File.read(path)
        end
        mtime = File::Stat.new(path).mtime
      end

      # find title
      if content.strip =~ /\A#\s*(.+)$/
        title = $~[1]
      else
        title = path
      end

      {
        :title => title,
        :anchor => Digest::MD5.hexdigest(path),
        :path => path,
        :content => content,
        :body => render_markdown(content), # GitHub::Markup.render(path),
        :git_status => git_status(path),
        :git_log => git_log(path),
        :commit => commit,
        :mtime => mtime,
        :filepath => path
      }
    end
  end
end

end
