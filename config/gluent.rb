# :data_dir should be a root directory of a git repository
# (i.e. :data_dir/.git must exist)

if ENV['GLUENT_DATA_DIR']
  $gluent_data_dir = ENV['GLUENT_DATA_DIR']
else
  $gluent_data_dir = File.expand_path("../../data", __FILE__)
end

git_dir = File.expand_path(".git", $gluent_data_dir)
if ! File.directory?(git_dir)
  raise RuntimeError.new("Invalid data_dir: #{$gluent_data_dir}")
end

class Application < Sinatra::Base
  set :data_dir, $gluent_data_dir
end
