require 'yaml'
require "erb"
require_relative 'argument_processor.rb'

class DatabaseConfigUpdater

  def initialize(arg_processor, args)
    raise ArgumentError.new("argument processor is nil")  if arg_processor.nil?
    @arg_processor = arg_processor
    @config = load_config_defaults
    @args = @arg_processor.process_args(args)
    print_errors if @args[:errors].any?
    route_request(@args)
  end

  private

  def print_errors
    @args[:errors].each do |error|
      puts colorize(error,31)
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
    puts ""
    @config.each do |app|
      if File.directory?(app[0].to_s)
        begin
          Dir.chdir app[0].to_s
        rescue
          continue
        end
        status =`git status`
        if status.include?("database.yml")
          Dir.chdir "host_app/config/"
          system("git checkout database.yml")
          status = `git status`
          puts colorize("Checked out:",32) + " #{app[0]}/#{app[1][:yml_location]}" if !status.include?("database.yml")
          Dir.chdir "../.."
        end
        Dir.chdir ".."
      end
    end
    puts ""
  end

  def switch_environment
    puts ""
    puts colorize("Configured the following for #{@args["-t"]}:",32)
    puts ""
    @config.each do |app|
      if File.directory?(app[0].to_s)
        Dir.chdir app[0].to_s
        configure_yaml_settings(app)
        status = `git status`
        puts "#{app[0]}/#{app[1]["yml_location"]}" if status.include?("database.yml")
        Dir.chdir ".."
      end
    end
    puts ""
  end

  def configure_yaml_settings(app)
    yaml = app[1]["yml_location"]
    config = YAML.load ERB.new(IO.read(yaml)).result
    set_host(config,yaml,app)
    set_database(config,yaml,app)
    set_username_and_password(config,yaml,app)
    save_yaml_to_file(config,yaml)
  end

  def save_yaml_to_file(config,yaml)
    File.open(yaml,'w') do |h|
      h.write config.to_yaml
    end
  end

  def set_host(config, yaml, app)
    if config[@args[:switches]["-e"]].has_key?("host")
      config[@args[:switches]["-e"]]["host"] = @args[:switches]["-t"]
      config["default"]["host"] = @args[:switches]["-t"]
    else
      config["default"]["host"] = @args[:switches]["-t"]
    end
  end

  def set_username_and_password(config,yaml,app)
    if config[@args[:switches]["-e"]].has_key?("username")
      config[@args[:switches]["-e"]]["username"] = @args[:switches]["-u"] || app[1]["username"]
      config[@args[:switches]["-e"]]["password"] =  @args[:switches]["-p"] || app[1]["password"]
      config["default"]["username"] =  @args[:switches]["-u"] || app[1]["username"]
      config["default"]["password"] =  @args[:switches]["-p"] || app[1]["password"]
    else
      config["default"]["username"] =  @args[:switches]["-u"] || app[1]["username"]
      config["default"]["password"] =  @args[:switches]["-p"] || app[1]["password"]
    end
  end

  def set_database(config,yaml_file, app)
    config[@args[:switches]["-e"]]["database"]  =  @args[:switches]["-d"] || app[1]["database_name"]
  end

  def defaults
    @config.each do |app|
    puts app[0]
    puts "Database: #{ app[1]["database_name"]}"
    puts "Username: #{ app[1]["username"]}"
    puts "Password: #{ app[1]["password"]}"
    puts ""
    end
  end

  def sage_apps_in_pwd
    Dir.glob('*').select {|f| puts f if sage_app? f}
  end

 def colorize(text, color_code)
   "\e[#{color_code}m#{text}\e[0m"
 end

 def print_help
   puts ""
   puts colorize("**********************************************************************************************************",32)
   puts colorize("**********************************************************************************************************",32)
   puts colorize("**",32) + colorize("                          This tool configures database settings for the                              ",31) + colorize("**",32)
   puts colorize("**",32) + colorize("                          targeted environment.                                                       ",31) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          To use run",33) + " sageone_env" + colorize(" with the desired switches and values                 ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          in the same directory as your Sage one apps.                                ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Use the following switches to pass arguments                                ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -t <host>          [",36) + colorize("required",31) + colorize("]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -e <environment>   [",36) + colorize("required",31) + colorize("]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -d <database name> [optional]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -u <username>      [optional]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -p <password>      [optional]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          e.g. -t my-uat-build -e test                                                ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Valid environments are 'test' and 'development'                             ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                         ",36) + " --revert  " + colorize("to checkout changes made to any database.yml                      ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          ",36) + "--default " + colorize("to output default settings                                        ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          ",36) + "--help -h " + colorize("to view help                                                      ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   puts colorize("**********************************************************************************************************",32)
   puts colorize("**********************************************************************************************************",32)
   puts ""

 end

  def sage_app?(dir)
    if is_directory(dir)
      @config.each do |app|
        return true if dir.include?(app.first)
      end
    end
    false
  end

  def is_directory(dir)
    return true
   File.directory dir
  end
end
