require "rubygems"
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'sinatra/reloader' if development?
require "github/markup"

class ImagePathFilter < HTML::Pipeline::Filter
  def call
    doc.search("img").each do |img|
      next if img['src'].nil?
      src = img['src'].strip

      if src =~ /^https?:\/\//
        next
      end

      if ! src.start_with? '/'
        img["src"] = "/data/" + src
      end
    end
    doc
  end
end

class Application < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::Partial

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
        {
          :filepath => filepath,
          :body => render_markdown(File.read(filepath)), # GitHub::Markup.render(filepath),
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
    # TODO: sanitize filepath
    entry = nil
    status = nil

    Dir.chdir($gluent_data_dir) do
      if ! File.exists?(filepath)
        pass
      end

      entry = {
        :filepath => filepath,
        :body => render_markdown(File.read(filepath)), # GitHub::Markup.render(filepath),
        :git_status => git_status(filepath)
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

    # TODO  sanitize filepath
    Dir.chdir($gluent_data_dir) do
      File.open(filepath, "w") do |f|
        f.print params[:content]
      end

      run_git "commit", "-m", "commit from gluent", "--", filepath
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
end

Dir[File.dirname(__FILE__) + "/config/*.rb"].each { |file| require file }
