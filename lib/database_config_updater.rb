require 'yaml'
require_relative 'argument_processor.rb'
require_relative 'sageone_connection.rb'

class DatabaseConfigUpdater

  def initialize(arg_processor, args)
    raise ArgumentError.new("argument processor is nil")  if arg_processor.nil?
    @pwd = Dir.pwd
    @arg_processor = arg_processor
    @connections = load_sageone_connections
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

  def load_sageone_connections
    connections = []
    defaults = load_config_defaults
    defaults.each do |default|
      connection = SageoneConnection.new
      connection.app_name = default[0]
      connection.database = default[1]["database_name"]
      connection.username = default[1]["username"]
      connection.password = default[1]["password"]
      connection.yaml_location = default[1]["yml_location"]
      connections.push connection
    end
    connections
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
        when "--detect_apps"
          apps = sage_apps_in_pwd
          apps.each do |app|
            puts colorize("Found: ",32) + app
          end
        end
      end
    elsif args[:switches].any?
      args[:switches].each do |switch|
        case switch.first
        when "-t"
          switch_environment
        end
      end
    end
  end

  def set_defaults
    settings = @args[:switches].select {|key, value| key.to_s.match(/-p|-u/) }
    defaults = load_config_defaults
    defaults.each do |default|
      settings.each do |setting|
        case setting[0]
        when "-p"
          default[1]['password'] = setting[1]
        when "-u"
          default[1]['username'] = setting[1]
        end
      end
    end
    path = File.dirname(__FILE__)
    save_yaml_to_file(defaults, File.join(path, '../config/database_defaults.yml' ))
  end

  def checkout_changes
    puts ""
    @connections.each do |connection|
      yaml_path = get_yaml_path(connection)
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
          puts colorize("Reverted to original:",32) + " #{connection.app_name}/#{connection.yaml_location}" if !status.include?("database.yml")
        else
          puts colorize("No changes to revert:",33) + " #{connection.app_name}/#{connection.yaml_location}" if !status.include?("database.yml")
        end
      end
    end
    Dir.chdir @pwd
    puts ""
  end

  def get_yaml_path(connection)
    "#{@pwd}/#{connection.app_name}/host_app/config/"
  end

  def switch_environment
    changes = {}
    @connections.each do |connection|
      yaml_path = get_yaml_path(connection)
      if File.directory?(yaml_path)
        Dir.chdir yaml_path
        can_proceed = if yaml_dirty?
                        user_wants_to_proceed_when_dirty?(connection.app_name) ? true : false
                      else
                        true
                      end
        configure_yaml_settings(connection) if can_proceed
        status = `git status`
        changes[connection.app_name] = {:file => "#{connection.app_name}/#{connection.yaml_location }" , :dirtied? => can_proceed }  if status.include?("database.yml")
      end
      Dir.chdir @pwd
    end
    output_changes(changes)
  end

  def output_changes(changes)
    puts ""
    if connection_has_changed?(changes,true)
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
      puts colorize('*************** No sageone apps found in the current directory ***************', 32) if sage_apps_in_pwd.empty?
    end
    puts ""
    puts colorize("The following have not been configured as you chose to keep existing changes:",32) if connection_has_changed?(changes,false)
    changes.each do |app, yaml|
      puts yaml[:file] if  yaml[:dirtied?] == false
    end

    puts ""
  end

  def connection_has_changed?(changes,is_dirty)
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

  def configure_yaml_settings(connection)
    yaml ="#{@pwd}/#{connection.app_name}/#{connection.yaml_location}"
    environment = @args[:switches]["-e"] || "development"
    prepare_database_yaml(yaml, environment)
    config = YAML.load_file(yaml)

    set_host(config,yaml, connection, environment)
    set_database(config, yaml, connection, environment)
    set_username_and_password(config, yaml, connection, environment)

    save_yaml_to_file(config,yaml)
  end

  def prepare_database_yaml(path_to_yaml, environment)
    File.open(path_to_yaml, 'w') {|file| file.truncate(0) }
    require 'yaml/store'
    database_yaml = YAML::Store.new 'database.yml'
    database_yaml.transaction do
      database_yaml[environment] = { 'adapter' => 'mysql2',
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

  def set_host(config, yaml, connection, environment)
    host = @args[:switches]["-t"].dup
    host = host.gsub(/datauki/,'dataad') if connection.app_name == 'new_accountant_edition'
    config[environment]["host"] = host
  end

  def set_username_and_password(config,yaml,connection, environment)
    config[environment]["username"] =  @args[:switches]["-u"] || connection.username
    config[environment]["password"] =  @args[:switches]["-p"] || connection.password
  end

  def set_database(config,yaml_file, connection, environment)
    config[environment]["database"]  =  @args[:switches]["-d"] || connection.database
  end

  def defaults
    @connections.each do |connection|
      puts connection.app_name
      puts "Database: #{ connection.database }"
      puts "Username: #{ connection.username }"
      puts "Password: #{ connection.password }"
      puts ""
    end
  end

  def sage_apps_in_pwd
    Dir.glob('*').select {|f| sage_app? f}
  end

  def colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end

  def print_help
    puts ""
    puts colorize("************************************************************************************************************************************************",32)
    puts colorize("************************************************************************************************************************************************",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                          This gem configures database settings for a targeted obfuscated data instance by                                  ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          overwriting the database.yml. This file is used by rails to connect to the database.                              ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                          Enclose parameter values in single quotes if they contain special characters or spaces.                           ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                          To use run",22) + colorize(" sageone_env",32) + colorize(" with the desired switches/commands and value                                               ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          in the same directory as your Sage one apps.                                                                      ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          Use the following switches to pass arguments.                                                                     ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          -t <host>          [",36) + colorize("required",31) + colorize("]                                                                                     ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                          -e <environment>   [optional] - defaults to development                                                           ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                          -u <username>      [optional]                                                                                     ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                          -p <password>      [optional]                                                                                     ",36) + colorize("**",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          e.g. sageone_env -t my-uat-build -e test                                                                          ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          Valid environments are 'test' and 'development'                                                                   ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                          Use the following commands                                                                                        ",22) + colorize("**",32)
    puts colorize("**",32) + colorize("                         ",36) + " --revert  " + colorize("to checkout changes made to any database.yml                                                            ",33) + colorize("**",32)
    puts colorize("**",32) + colorize("                          ",36) + "--defaults " + colorize("to output default settings                                                                             ",33) + colorize("**",32)
    puts colorize("**",32) + colorize("                          ",36) + "--detect_apps " + colorize("to view sageone apps found in the current directory                                                 ",33) + colorize("**",32)
    puts colorize("**",32) + colorize("                          ",36) + "--set_defaults -p <password> -u <username> " + colorize("to set default values                                                  ",33) + colorize("**",32)
    puts colorize("**",32) + colorize("                          ",36) + "--help -h " + colorize("to view help                                                                                            ",33) + colorize("**",32)
    puts colorize("**",32) + colorize("                                                                                                                                            ",36) + colorize("**",32)
    puts colorize("************************************************************************************************************************************************",32)
    puts colorize("************************************************************************************************************************************************",32)
    puts ""
  end

  def sage_app?(dir)
    if File.directory? dir
      @connections.each do |connection|
        return true if dir.include?(connection.app_name)
      end
    end
    false
  end
end
