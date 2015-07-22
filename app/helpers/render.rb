
module Gluent

module RenderHelper
#   def find_template(views, name, engine, &block)
#     _, folder = views.detect { |k,v| engine == Tilt[k] }
#     folder ||= views[:default]
#     p [settings.public_folder]
#     super("#{settings.root}/#{folder}", name, engine, &block)
#   end

  def stylesheets
    %w[gumby style].map do |path|
      "<link rel='stylesheet' type='text/css' media='all' href='/css/#{path}.css'>"
    end.join "\n"
  end

  def javascripts
    %w[libs/modernizr-2.6.2.min
        libs/jquery-2.0.2.min
        libs/gumby
        libs/ui/gumby.checkbox
        libs/ui/gumby.fixed
        libs/ui/gumby.navbar
        libs/ui/gumby.radiobtn
        libs/ui/gumby.retina
        libs/ui/gumby.skiplink
        libs/ui/gumby.tabs
        libs/ui/gumby.toggleswitch
        libs/gumby.init
        libs/ui/jquery.validation
        main
        plugins
        script].map do |path|
      "<script src='/js/#{path}.js'></script>"
    end.join "\n"
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def render_markdown(src)
    pipe = HTML::Pipeline.new [HTML::Pipeline::MarkdownFilter, ImagePathFilter]
    pipe.call(src)[:output].to_s
  end
end

end # Gluent
