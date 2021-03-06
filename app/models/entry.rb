
module Gluent

class Entry
  include GitHelper

  attr_accessor :score

  class << self
    include GitHelper
    include RenderHelper
    include ::Enumerable

    def each
      all_path.each do |path|
        entry = get(path)
        yield(entry)
      end
    end

    def all
      self.map do |x|
        x
      end
    end

    def get(path, commit_hash = nil)
      content = nil
      mtime = nil
      Dir.chdir($gluent_data_dir) do
        if commit_hash
          content = git.object("#{commit_hash}:#{path}").contents
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

      self.new({
                 :title => title,
                 :anchor => Digest::MD5.hexdigest(path),
                 :path => path,
                 :content => content,
                 :body => render_markdown(content), # GitHub::Markup.render(path),
                 :commit => commit_hash,
                 :mtime => mtime,
                 :filepath => path
               })
    end

    private

    def all_path
      Dir.chdir($gluent_data_dir) do
        Dir.glob("**/*.md").sort_by do |path|
          - File::Stat.new(path).mtime.to_f
        end
      end
    end
  end

  def initialize(attrs)
    @attributes = {
      :title => nil,
      :anchor => nil,
      :path => nil,
      :content => nil,
      :body => nil,
      :commit => nil,
      :mtime => nil,
      :filepath => nil
    }.merge(attrs).symbolize_keys

    if ! @attributes[:filepath]
      raise ArgumentError.new("Entry cannot be initialized without filepath")
    end

    @dirty = false
  end

  def [](key)
    @attributes[key.to_sym]
  end

  def []=(key, val)
    @dirty = true
    key = key.to_sym
    if key == :content
      val = val.gsub(/\r\n/, "\n")
    end
    @attributes[key.to_sym] = val
  end

  def heads
    if @heads
      return @heads
    end

    # extract H2 heads
    doc = Nokogiri.parse("<html>" + self[:body] + "</html>")
    @heads = doc.search('//h2').map do |head|
      head.inner_text
    end
  end

  def gitlog
    git_log(self[:path])
  end

  def gitstatus
    git_status(self[:path])
  end

  def commit
    Dir.chdir($gluent_data_dir) do
      try_git "add", self[:filepath]
      try_git "commit", "-m", "commit from gluent"
    end
    update_groonga_record
  end

  def save(do_commit = false)
    unless @dirty
      return true
    end

    Dir.chdir($gluent_data_dir) do
      File.open(self[:filepath], "w") do |f|
        f.print(self[:content])
      end

      if do_commit
        self.commit
      end
    end

    @dirty = false

    update_groonga_record

    true
  end

  def update_groonga_record
    Dir.chdir($top_dir) do
      Groonga["Entries"].add(self[:filepath],
                             path: self[:filepath],
                             title: self[:title],
                             body: self[:content],
                             mtime: self[:mtime])
    end
  end
end

end
