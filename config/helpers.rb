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

    def h(text)
      Rack::Utils.escape_html(text)
    end

    def run_git(*cmd)
      cmd = ["git", *cmd]
      stdout = nil
      status = nil

      begin
        status = IO.popen(cmd, "r") do |io|
          stdout = io.read
          io.close
          $?
        end
      rescue Errno::ENOENT
        status = nil
      end

      if status.nil? || status.exitstatus != 0
        halt "Failed to run: #{cmd.join(' ')}"
      end

      stdout
    end

    def git_status(filepath)
      stdout = run_git "status", "--porcelain", "--", filepath
      stdout.each_line do |line|
        if line.include?(filepath)
          return line.split[0]
        end
      end

      nil
    end
  end
end
