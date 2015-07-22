
namespace :groonga do
  task :load_config do
    require 'groonga'
    require 'yaml'
    $groonga_config = YAML.load(open("config/groonga.yml"))
  end

  task :open => :load_config do
    Groonga::Database.open($groonga_config["path"])
  end

  desc "Create the Groonga database."
  task :create => :load_config do
    begin
      Groonga::Database.create($groonga_config)
      puts "Created the database: #{$groonga_config["path"]}"
    rescue Groonga::FileExists
      puts "Already exists."
    end
  end

  desc "Drop the Groonga database."
  task :drop => :load_config do
    db = Groonga::Database.open($groonga_config["path"])
    db.remove
  end

  namespace :schema do
    desc "Load the schema."
    task :load => "groonga:open" do
      require './db/groonga-schema'
      create_groonga_tables()
    end
  end

  desc "Populate groonga database."
  task :populate => "groonga:schema:load" do
    sh "./scripts/populate_groonga"
  end
end

namespace :thin do
  desc "Start thin server."
  task :start do
    sh "thin -s 1 -C thin-config.yml -R config.ru start"
  end

  desc "Stop thin server."
  task :stop do
    sh "thin -s 1 -C thin-config.yml -R config.ru stop"
  end

  desc "Restart thin server."
  task :restart do
    sh "thin -s 1 -C thin-config.yml -R config.ru restart"
  end
end
