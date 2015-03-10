class Application < Sinatra::Base
  configure do
    set :views, sass: "public/css", coffee: "public/js", erb: "views", default: "views"
  end

  configure :production do
  end
end
