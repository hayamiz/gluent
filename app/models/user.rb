require 'optparse'
require 'digest/sha1'

module Gluent

class User
  attr_reader :username

  def self.authenticate(params)
    passwd_data = YAML.load(File.read(File.expand_path("config/passwd", $top_dir)))
    passwd_data.each do |user_entry|
      if user_entry[:username] == params[:username] &&
          user_entry[:hashed_password] == Digest::SHA1.hexdigest(params[:password])
        return User.new(user_entry[:username])
      end
    end

    nil
  end

  def self.get(username)
    passwd_data = YAML.load(File.read(File.expand_path("config/passwd", $top_dir)))
    passwd_data.each do |user_entry|
      if user_entry[:username] == username
        return User.new(username)
      end
    end

    nil
  end

  def initialize(username)
    @username = username
  end
end

end
