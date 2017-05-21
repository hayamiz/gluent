
module Gluent

class Application < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::Partial

  set :session_secret, SESSION_SECRET
  enable :sessions
  set :root, File.expand_path("../..", __FILE__)
  set :public_folder, File.expand_path("../../../public", __FILE__)

  register do
    def auth(type)
      condition do
        redirect "/login" unless send("is_#{type}?")
      end
    end
  end

  helpers do
    def is_user?
      @user != nil
    end
  end

  before do
    @user = User.get(session[:username])
  end

  get "/login" do
    erb :login
  end

  post "/login" do
    session[:username] = User.authenticate(params).username

    redirect to("/")
  end

  get "/logout" do
    session[:username] = nil

    redirect to("/login")
  end

  get "/", :auth => :user do
    per_page = 20
    entries = []
    num_pages = 1
    page_idx = (params[:page] || 1).to_i # 1-origin

    entries = Entry.all

    num_pages = (entries.size - 1) / per_page + 1
    if page_idx > num_pages
      page_idx = num_pages
    end

    entries = entries[(per_page * (page_idx - 1)), per_page]

    erb :index, :locals => {:entries => entries, :num_pages => num_pages, :page_idx => page_idx}
  end

  get "/create", :auth => :user  do
    erb :create, :locals => {:default_path => Time.now.strftime("%Y%m%d.md")}
  end

  post "/create", :auth => :user  do
    filepath = params[:filepath]

    # TODO: sanitize filepath
    Dir.chdir($gluent_data_dir) do
      if File.exists?(filepath)
        halt "#{h filepath} already exists!"
      end

      dir = File.dirname(filepath)
      unless File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end

      File.open(filepath, "w").close

      run_git "add", filepath
    end

    redirect to("/edit/#{filepath}")
  end

  get "/show/*", :auth => :user  do |filepath|
    if params[:commit]
      commit = params[:commit]
    else
      commit = nil
    end

    # TODO: sanitize filepath
    entry = Entry.get(filepath, commit)

    @page_title = entry[:title]

    erb :show, :locals => {:entry => entry}
  end

  get "/data/*", :auth => :user  do |filepath|
    # TODO sanitize filepath

    Dir.chdir($gluent_data_dir) do
      if ! File.exists? filepath
        halt 404, "no such file: #{filepath}"
      end
    end

    send_file File.expand_path(filepath, $gluent_data_dir)
  end

  get "/edit/*", :auth => :user  do |filepath|
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

  post "/edit/*", :auth => :user  do |filepath|
    # TODO  sanitize filepath

    if params[:do_commit].nil?
      do_commit = false
    else
      if params[:do_commit] == "true"
        do_commit = true
      else
        do_commit = false
      end
    end

    entry = Entry.get(filepath)
    entry[:content] = params[:content]
    entry.save(do_commit)

    unless params[:api_call]
      redirect to("/show/#{filepath}")
    end
  end

  post "/preview", :auth => :user  do
    unless params[:content]
      halt "no content"
    end

    # GitHub::Markup.render("content.md", params[:content])
    render_markdown(params[:content])
  end

  post "/upload", :auth => :user  do
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

  get "/commit/*", :auth => :user  do |filepath|
    # TODO: sanitize filepath
    Dir.chdir($gluent_data_dir) do
      if ! File.exists?(filepath)
        halt "no such file: #{filepath}"
      end
      entry = Entry.get(filepath)
      entry.commit
    end

    redirect to("/show/#{filepath}")
  end

  get "/search", :auth => :user  do
    @query = params[:query]
    @sort_by = params[:sort_by]

    matches = Groonga["Entries"].select do |entry|
      @query.split.map do |word|
        _title = entry.match_target do |_entry|
          _entry.title * 10
        end
        _path = entry.match_target do |_entry|
          _entry.path * 10
        end
        _body = entry.match_target do |_entry|
          _entry.body * 1
        end
        (_title =~ word) | (_path =~ word) | (_body =~ word)
      end.inject(&:|)
    end

    entries = matches.map do |match|
      entry = Entry.get(match[:path])
      entry.score = match.score

      entry
    end

    @sort_by ||= "score"
    sort_proc = nil

    case @sort_by
    when "score"
      sort_proc = lambda do |entry|
        entry.score * -1.0
      end
    when "date"
      sort_proc = lambda do |entry|
        entry[:mtime].to_i * -1
      end
    end

    entries = entries.sort_by(&sort_proc)

    erb :search, locals: {query: @query, sort_by: @sort_by, entries: entries}
  end

  get "/sandbox" do
    erb :sandbox
  end
end

end # module Gluent
