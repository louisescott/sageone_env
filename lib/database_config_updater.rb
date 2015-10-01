require 'yaml'
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
        when "--help", "-h"
          print_help
          return
        when "--defaults"
          defaults
        when "--revert"
          checkout_changes
        when "--set_defaults"
          puts 'configuration changes saved' if set_defaults
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
        when "-t"
          print_help unless  args[:switches].include?("-e")
        end
      end
    end
  end

  def set_defaults
    settings = @args[:switches].select {|key, value| key.to_s.match(/-p|-u/) }
    defaults = load_config_defaults
    defaults.each do |repo|
      settings.each do |setting|
        case setting[0]
        when "-p"
          repo[1]['password'] = setting[1]
        when "-u"
          repo[1]['username'] = setting[1]
        end
      end
    end
    path = File.dirname(__FILE__)
    save_yaml_to_file(defaults, File.join(path, '../config/database_defaults.yml' ))
  end

  def checkout_changes
    puts ""
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
          puts colorize("reverted to original:",32) + " #{app[0]}/#{app[1]["yml_location"]}" if !status.include?("database.yml")
        end
      end
    end
      Dir.chdir @pwd
    puts ""
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
    puts ""
    if config_has_changed?(changes,true)
      puts colorize("Configured #{colorize("for host:",32)} #{colorize("'#{@args[:switches]["-t"]}'",33)} #{colorize("in the following apps:",32)} ",32)
      puts ""
      changes.each do |app, dirtied|
        puts colorize("Configured: ",32) + dirtied[:file] if  dirtied[:dirtied?] == true
      end
      puts ""
      puts "#{colorize("NOTE - the configured files have been overwritten:",22)} #{colorize(" do no commit the changes.",31)}"
      puts colorize("To undo the changes execute: #{colorize("sageone_env --revert",32)}",22)
      puts ""
    else
      puts 'no changes made'
      puts 'no sageone apps found in the current directory' if sage_apps_in_pwd.empty?
    end
    puts ""
    puts colorize("The following have not been configured as you chose to keep existing changes:",32) if config_has_changed?(changes,false)
    changes.each do |app, dirtied|
      puts dirtied[:file] if  dirtied[:dirtied?] == false
    end

    puts ""
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
    prepare_database_yaml(yaml)
    config = YAML.load_file(yaml)
    set_host(config,yaml,app)
    set_database(config,yaml,app)
    set_username_and_password(config,yaml,app)
    save_yaml_to_file(config,yaml)
  end

  def prepare_database_yaml(path_to_yaml)
    File.open(path_to_yaml, 'w') {|file| file.truncate(0) }
    require 'yaml/store'
    database_yaml = YAML::Store.new 'database.yml'
    database_yaml.transaction do
    database_yaml[@args[:switches]["-e"]] = { 'adapter' => 'mysql2',
                                 'encoding' =>'utf8',
                                 'pool' => 5,
                                 'username' => 'username',
                                 'password' => 'password',
                                 'host' => 'localhost',
                                 'database' => 'database'}
    end
  end

  def save_yaml_to_file(config,yaml)
    File.open(yaml,'w') do |h|
      h.write config.to_yaml
    end
  end

  def set_host(config, yaml, app)
    host = @args[:switches]["-t"].dup
    host = host.gsub(/datauki/,'dataad') if app[0] == 'new_accountant_edition'
    config[@args[:switches]["-e"]]["host"] = host
  end

  def set_username_and_password(config,yaml,app)
    config[@args[:switches]["-e"]]["username"] =  @args[:switches]["-u"] || app[1]["username"]
    config[@args[:switches]["-e"]]["password"] =  @args[:switches]["-p"] || app[1]["password"]
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
   puts colorize("******************************************************************************************************************************",32)
   puts colorize("******************************************************************************************************************************",32)
   puts colorize("**",32) + colorize("                          This tool configures database settings for a targeted environment by                            ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          overwriting the database.yml. This file is used by rails to connect to the database.            ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                                          ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Enclose parameter values in qoutes if they contain special characters or spaces.                ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                                          ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          To use run",22) + colorize(" sageone_env",32) + colorize(" with the desired switches/commands and value                             ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          in the same directory as your Sage one apps.                                                    ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                                          ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Use the following switches to pass arguments.                                                   ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -t <host>          [",36) + colorize("required",31) + colorize("]                                                                   ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -e <environment>   [",36) + colorize("required",31) + colorize("]                                                                   ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -d <database name> [optional]                                                                   ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -u <username>      [optional]                                                                   ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -p <password>      [optional]                                                                   ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                                          ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          e.g. sageone_env -t my-uat-build -e test                                                        ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Valid environments are 'test' and 'development'                                                 ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                                          ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Use the following commands                                                                      ",22) + colorize("**",32)
   puts colorize("**",32) + colorize("                         ",36) + " --revert  " + colorize("to checkout changes made to any database.yml                                          ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          ",36) + "--defaults " + colorize("to output default settings                                                            ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          ",36) + "--set_defaults -p <password> -u <username> " + colorize("to set default values                                ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          ",36) + "--help -h " + colorize("to view help                                                                          ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                                          ",36) + colorize("**",32)
   puts colorize("******************************************************************************************************************************",32)
   puts colorize("******************************************************************************************************************************",32)
   puts ""
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
