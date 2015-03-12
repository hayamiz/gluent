require "rubygems"
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'sinatra/reloader' if development?
require "github/markup"

class Application < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::Partial

  get "/" do
    entries = []

    Dir.chdir($gluent_data_dir) do
      entries = Dir.glob("**/*.md").map do |filepath|
        {
          :filepath => filepath,
          :body => GitHub::Markup.render(filepath),
          :git_status => git_status(filepath)
        }
      end.sort_by do |entry|
        File::Stat.new(entry[:filepath]).mtime
      end.reverse
    end
    erb :index, :locals => {:entries => entries}
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

  get "/show/:filepath" do |filepath|
    # TODO: sanitize filepath
    entry = nil
    status = nil

    Dir.chdir($gluent_data_dir) do
      if ! File.exists?(filepath)
        pass
      end

      entry = {
        :filepath => filepath,
        :body => GitHub::Markup.render(filepath),
        :git_status => git_status(filepath)
      }
    end
    erb :show, :locals => {:entry => entry}
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
    end

    redirect to("/show/#{filepath}")
  end

  get "/preview" do
    unless params[:content]
      halt "no content"
    end

    GitHub::Markup.render("content.md", params[:content])
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
