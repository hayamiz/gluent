class Application < Sinatra::Base
  helpers do
    def find_template(views, name, engine, &block)
      _, folder = views.detect { |k,v| engine == Tilt[k] }
      folder ||= views[:default]
      super("#{settings.root}/#{folder}", name, engine, &block)
    end

    def stylesheets
      %w[lib/jquery-ui.min style].map do |path|
        "<link rel='stylesheet' type='text/css' media='all' href='/css/#{path}.css'>"
      end.join "\n"
    end

    def javascripts
      %w[lib/jquery.min lib/jquery-ui.min script].map do |path|
        "<script src='/js/#{path}.js'></script>"
      end.join "\n"
    end
  end
end
