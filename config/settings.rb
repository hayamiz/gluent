class Application < Sinatra::Base
  configure do
    set :views, css: "public/css", js: "public/js", erb: "views", default: "views"
  end

  configure :production do
  end
end
