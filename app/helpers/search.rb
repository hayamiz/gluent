# -*- coding: utf-8 -*-

module Gluent

module SearchHelper
  # parse a query string into an expression tree
  # FIXME: currently returns an array of RegExp objects, which represents AND-ed conditions
  def parse_query(query_string)
    query_string.split(/[\s　]+/).map do |keyword|
      Regexp.compile(keyword, Regexp::IGNORECASE)
    end
  end

  def match_file(file_path, search_exp)
    content = File.read(file_path)

    search_exp.all? do |regexp|
      regexp =~ content
    end
  end
end # SearchHelper

end # Gluent
