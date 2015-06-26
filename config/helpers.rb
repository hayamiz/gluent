require 'git'

class Application
  helpers do
    include Gluent::RenderHelper
    include Gluent::GitHelper

  end # helpers
end
