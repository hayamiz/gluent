require "rubygems"
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require "github/markup"

class Application < Sinatra::Base
  register Sinatra::R18n
  register Sinatra::Partial

  get "/" do
    entries = []

    Dir.chdir($gluent_data_dir) do
      entries = Dir.glob("*.md").map do |filename|
        {
          :filename => filename,
          :body => GitHub::Markup.render(filename)
        }
      end.sort_by do |entry|
        File::Stat.new(entry[:filename]).mtime
      end.reverse
    end
    erb :index, :locals => {:entries => entries}
  end
end

Dir[File.dirname(__FILE__) + "/config/*.rb"].each { |file| require file }
