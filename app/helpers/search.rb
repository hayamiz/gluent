
module Gluent

module SearchHelper
  # parse a query string into an expression tree
  # FIXME: currently returns an array of RegExp objects, which represents AND-ed conditions
  def parse_query(query_string)
    [Regexp.compile(query_string)]
  end
end # SearchHelper

end # Gluent
