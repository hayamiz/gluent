
class Application < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::Partial

  set :root, File.expand_path("../..", __FILE__)
  set :public_folder, File.expand_path("../../../public", __FILE__)

  get "/" do
    per_page = 20
    entries = []
    num_pages = 1
    page_idx = (params[:page] || 1).to_i # 1-origin

    Dir.chdir($gluent_data_dir) do
      entry_files = Dir.glob("**/*.md").sort_by do |filepath|
        File::Stat.new(filepath).mtime
      end.reverse

      num_pages = (entry_files.size - 1) / per_page + 1
      if page_idx > num_pages
        page_idx = num_pages
      end

      entry_files = entry_files[(per_page * (page_idx - 1)),per_page]

      entries = entry_files.map do |filepath|
        content = File.read(filepath)

        # find title
        if content.strip =~ /\A#\s*(.+)$/
          title = $~[1]
        else
          title = filepath
        end

        {
          :title => title,
          :anchor => Digest::MD5.hexdigest(filepath),
          :filepath => filepath,
          :body => render_markdown(content), # GitHub::Markup.render(filepath),
          :git_status => git_status(filepath)
        }
      end
    end

    erb :index, :locals => {:entries => entries, :num_pages => num_pages, :page_idx => page_idx}
  end

  get "/create" do
    erb :create, :locals => {:default_path => Time.now.strftime("%Y%m%d.md")}
  end

  post "/create" do
    filepath = params[:filepath]

    # TODO: sanitize filepath
    Dir.chdir($gluent_data_dir) do
      if File.exists?(filepath)
        halt "#{h filepath} already exists!"
      end
      File.open(filepath, "w").close

      run_git "add", filepath
    end

    redirect to("/edit/#{filepath}")
  end

  get "/show/*" do |filepath|
    if params[:commit]
      commit = params[:commit]
    else
      commit = nil
    end

    # TODO: sanitize filepath
    entry = nil
    status = nil

    Dir.chdir($gluent_data_dir) do
      if ! File.exists?(filepath)
        pass
      end

      if commit
        content = git.object("#{commit}:#{filepath}").contents
      else
        content = File.read(filepath)
      end

      entry = {
        :filepath => filepath,
        :body => render_markdown(content), # GitHub::Markup.render(filepath),
        :git_status => git_status(filepath),
        :git_log => git_log(filepath),
        :commit => commit,
      }
    end
    erb :show, :locals => {:entry => entry}
  end

  get "/data/*" do |filepath|
    # TODO sanitize filepath

    Dir.chdir($gluent_data_dir) do
      if ! File.exists? filepath
        halt 404, "no such file: #{filepath}"
      end
    end

    send_file File.expand_path(filepath, $gluent_data_dir)
  end

  get "/edit/:filepath" do |filepath|
    # TODO sanitize filepath
    entry = nil
    Dir.chdir($gluent_data_dir) do
      entry = {
        :filepath => filepath,
        :source => File.read(filepath)
      }
    end
    erb :edit, :layout => :edit_layout, :locals => {:entry => entry}
  end

  post "/edit/:filepath" do |filepath|
    params[:content].gsub!(/\r\n/, "\n")
    if params[:do_commit].nil?
      do_commit = false
    else
      do_commit = params[:do_commit]
    end

    # TODO  sanitize filepath
    Dir.chdir($gluent_data_dir) do
      File.open(filepath, "w") do |f|
        f.print params[:content]
      end

      if do_commit
        try_git "add", filepath
        try_git "commit", "-m", "commit from gluent"
      end
    end

    redirect to("/show/#{filepath}")
  end

  post "/preview" do
    unless params[:content]
      halt "no content"
    end

    # GitHub::Markup.render("content.md", params[:content])
    render_markdown(params[:content])
  end

  post "/upload" do
    content_type :json

    file_keys = params.keys.select do |key_sym|
      key_sym.to_s =~ /^files_(\d+)$/
    end

    if file_keys.size == 0
      halt "no file"
    end

    uploaded_files = file_keys.map do |key|
      params[key]
    end.map do |file|
      # find available file name
      filename = file[:filename]
      mime_type = file[:type]
      tmpfile = file[:tempfile]

      filepath = available_filepath(filename, mime_type)
      $stderr.puts(filepath)
      File.open(filepath, "w") do |f|
        while blk = tmpfile.read(65536)
          f.print(blk)
        end
      end

      run_git "add", filepath

      rel_path = Pathname.new(filepath).relative_path_from(Pathname.new($gluent_data_dir)).to_s
      $stderr.puts(rel_path)
      rel_path = "/data/" + rel_path

      {
        :filename => filename,
        :path => rel_path,
        :type => mime_type
      }
    end

    uploaded_files.to_json
  end

  get "/commit/:filepath" do |filepath|
    # TODO: sanitize filepath
    Dir.chdir($gluent_data_dir) do
      if ! File.exists?(filepath)
        halt "no such file: #{filepath}"
      end

      run_git "commit", "-m", "commit from gluent", "--", filepath
    end

    redirect to("/show/#{filepath}")
  end

  get "/sandbox" do
    erb :sandbox
  end
end