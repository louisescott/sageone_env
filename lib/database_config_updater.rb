require 'yaml'
require "erb"
require 'active_support/all'

require_relative 'argument_processor.rb'

class DatabaseConfigUpdater

  def initialize(arg_processor, args)
    raise ArgumentError.new("argument processor is nil")  if arg_processor.nil?
    @pwd = Dir.pwd
    @arg_processor = arg_processor
    @config = load_config_defaults
    @args = @arg_processor.process_args(args)
    print_errors if @args[:errors].any?
    route_request(@args)
  end

  private

  def print_errors
    @args[:errors].each do |error|
      STDOUT.puts colorize(error,31)
    end
  end

  def load_config_defaults
    path = File.dirname(__FILE__)
    database_defaults = File.join(path, '../config/database_defaults.yml' )
    YAML.load_file(File.open(database_defaults))
  end

  def route_request(args)
    if args[:commands].any?
      args[:commands].each do |command|
        case command
        when "--help"
          print_help
        when "--default"
          defaults
        when "--revert"
          checkout_changes
        end
      end
    elsif args[:switches].any?
      args[:switches].each do |switch|
        case switch.first
        when "-e"
          if args[:switches].include?("-t")
            switch_environment
          else
            print_help
          end
        end
      end
    end
  end

  def checkout_changes
    STDOUT.puts ""
    @config.each do |app|
    yaml_path = get_yaml_path(app)
      if File.directory?(yaml_path)
        begin
          Dir.chdir yaml_path
        rescue
          continue
        end
        status =`git status`
        if status.include?("database.yml")
          system("git checkout database.yml")
          status = `git status`
          STDOUT.puts colorize("Checked out:",32) + " #{app[0]}/#{app[1][:yml_location]}" if !status.include?("database.yml")
        end
      end
    end
      Dir.chdir @pwd
    STDOUT.puts ""
  end

  def get_yaml_path(app)
    "#{@pwd}/#{app[0].to_s}/host_app/config/"
  end

  def switch_environment
    ENV['DATABASE_UID'] = "DB"
    changes = {}
    @config.each do |app|
    yaml_path = get_yaml_path(app)
      if File.directory?(yaml_path)
        Dir.chdir yaml_path
        can_proceed = if yaml_dirty?
                        user_wants_to_proceed_when_dirty?(app[0]) ? true : false
                      else
                        true
                      end
        configure_yaml_settings(app) if can_proceed
        status = `git status`
        changes[app[0]] = {:file => "#{app[0]}/#{app[1]["yml_location"]}" , :dirtied? => can_proceed }  if status.include?("database.yml")
      end
      Dir.chdir @pwd
    end
    output_changes(changes)
  end

  def output_changes(changes)
    STDOUT.puts ""
    STDOUT.puts colorize("Configured #{colorize("'#{@args[:switches]["-e"]}'",33)} #{colorize("for target:",32)} #{colorize("'#{@args[:switches]["-t"]}'",33)} #{colorize("in the following apps:",32)} ",32) if config_has_changed?(changes,true)

    changes.each do |app, dirtied|
      STDOUT.puts dirtied[:file] if  dirtied[:dirtied?] == true
    end
    STDOUT.puts ""
    STDOUT.puts colorize("The following have not been configured as you chose to keep existing changes:",32) if config_has_changed?(changes,false) 
    changes.each do |app, dirtied|
      STDOUT.puts dirtied[:file] if  dirtied[:dirtied?] == false
    end
    STDOUT.puts ""
  end

  def config_has_changed?(changes,is_dirty)
    changes.select{|app,dirtied| dirtied[:dirtied?]==is_dirty}.any?
  end

  def yaml_dirty?
    status = `git status`
    status.include?("database.yml")
  end

  def user_wants_to_proceed_when_dirty?(app_name)
    input = prompt colorize('%-85s' % "#{app_name} database.yml already has changes, these will be overwritten.  ",31) + "Proceed? [ y, n] "
    input.chomp.upcase == "Y"
  end

  def prompt(*args)
    print(*args)
    STDIN.gets
  end

  def configure_yaml_settings(app)
    yaml ="#{@pwd}/#{app[0]}/#{app[1]["yml_location"]}"
    config = YAML.load ERB.new(IO.read(yaml)).result
    set_host(config,yaml,app)
    set_database(config,yaml,app)
    set_username_and_password(config,yaml,app)
    save_yaml_to_file(config,yaml)
  end

  def save_yaml_to_file(config,yaml)
    File.open(yaml,'w') do |h|
      h.puts config.to_yaml
    end
  end

  def set_host(config, yaml, app)
    if config[@args[:switches]["-e"]].has_key?("host")
      config[@args[:switches]["-e"]]["host"] = @args[:switches]["-t"]
    else
      config["default"]["host"] = @args[:switches]["-t"] if !config["default"].nil?
    end
  end

  def set_username_and_password(config,yaml,app)
    if config[@args[:switches]["-e"]].has_key?("username")
      config[@args[:switches]["-e"]]["username"] = @args[:switches]["-u"] || app[1]["username"]
      config[@args[:switches]["-e"]]["password"] =  @args[:switches]["-p"] || app[1]["password"]
    else
      if !config["default"].nil?
        config["default"]["username"] =  @args[:switches]["-u"] || app[1]["username"] 
        config["default"]["password"] =  @args[:switches]["-p"] || app[1]["password"] 
      end
    end
  end

  def set_database(config,yaml_file, app)
    config[@args[:switches]["-e"]]["database"]  =  @args[:switches]["-d"] || app[1]["database_name"]
  end

  def defaults
    @config.each do |app|
    STDOUT.puts app[0]
    STDOUT.puts "Database: #{ app[1]["database_name"]}"
    STDOUT.puts "Username: #{ app[1]["username"]}"
    STDOUT.puts "Password: #{ app[1]["password"]}"
    STDOUT.puts ""
    end
  end

  def sage_apps_in_pwd
    Dir.glob('*').select {|f| STDOUT.puts f if sage_app? f}
  end

 def colorize(text, color_code)
   "\e[#{color_code}m#{text}\e[0m"
 end

 def print_help
   STDOUT.puts ""
   STDOUT.puts colorize("**********************************************************************************************************",32)
   STDOUT.puts colorize("**********************************************************************************************************",32)
   STDOUT.puts colorize("**",32) + colorize("                          This tool configures database settings for the                              ",31) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          targeted environment.                                                       ",31) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          To use run",33) + " sageone_env" + colorize(" with the desired switches and values                 ",33) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          in the same directory as your Sage one apps.                                ",33) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          Use the following switches to pass arguments                                ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          -t <host>          [",36) + colorize("required",31) + colorize("]                                               ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          -e <environment>   [",36) + colorize("required",31) + colorize("]                                               ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          -d <database name> [optional]                                               ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          -u <username>      [optional]                                               ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          -p <password>      [optional]                                               ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          e.g. -t my-uat-build -e test                                                ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          Valid environments are 'test' and 'development'                             ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                         ",36) + " --revert  " + colorize("to checkout changes made to any database.yml                      ",33) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          ",36) + "--default " + colorize("to output default settings                                        ",33) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                          ",36) + "--help -h " + colorize("to view help                                                      ",33) + colorize("**",32)
   STDOUT.puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   STDOUT.puts colorize("**********************************************************************************************************",32)
   STDOUT.puts colorize("**********************************************************************************************************",32)
   STDOUT.puts ""
 end

  def sage_app?(dir)
    if File.directory? dir
      @config.each do |app|
        return true if dir.include?(app.first)
      end
    end
    false
  end
end
