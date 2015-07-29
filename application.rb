require "rubygems"
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'sinatra/reloader' if development?
require "github/markup"
require 'digest/md5'
require 'fileutils'
require 'uri'
require 'pathname'
require 'logger'
require 'yaml'

$top_dir = Pathname.new(File.expand_path("../", __FILE__))

gluent_config = YAML.load_file($top_dir + "config" + "gluent.yml")
ENV['GLUENT_DATA_DIR'] = gluent_config["data_dir"]

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

Dir[File.dirname(__FILE__) + "/app/helpers/*.rb"].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + "/app/models/*.rb"].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + "/app/controllers/*.rb"].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + "/config/*.rb"].each do |file|
  require file
end

# open Groonga database
Groonga::Database.open(
  YAML.load_file(File.expand_path('../config/groonga.yml', __FILE__))["path"])
