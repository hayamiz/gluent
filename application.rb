require "rubygems"
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'sinatra/reloader' if development?
require "github/markup"
require 'digest/md5'

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

Dir[File.dirname(__FILE__) + "/app/controllers/*.rb"].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + "/app/helpers/*.rb"].each do |file|
  require file
end

Dir[File.dirname(__FILE__) + "/config/*.rb"].each do |file|
  require file
end
