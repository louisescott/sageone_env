require 'yaml'
require "erb"
require 'pry'
class DatabaseConfig

  def initialize(arg_processor)
    return nil if arg_processor.nil?
    @arg_processor = arg_processor
    @apps = {:new_accountant_edition => 
                                   {:yml_location => 'host_app/config/database.yml',
                                    :database_name => 'sageone_acc_uk', 
                                    :username => 'nigel', 
                                    :password => 'password'},
             :mysageone_uk => 
                                   {:yml_location => 'host_app/config/database.yml',
                                     :database_name => 'sageone_mso_uk', 
                                     :username => 'nigel', 
                                     :password => 'password'},
             :sage_one_addons_uk => 
                                   {:yml_location => 'host_app/config/database.yml',
                                     :database_name => 'sageone_addons_uk', 
                                     :username => 'nigel', 
                                     :password => 'password'},
             :chorizo => 
                                   {:yml_location => 'host_app/config/database.yml',
                                    :database_name => 'sageone_collaborate_uk', 
                                    :username => 'nigel', 
                                    :password => 'password'},
             #:sage_one_advanced => 
              #                     {:yml_location => 'host_app/config/database.yml',
               #                     :database_name => 'sageone_ext_uk',
                #                    :username => 'nigel', 
                 #                   :password => 'password'},
             :sage_one_accounts_uk => 
                                   {:yml_location => 'host_app/config/database.yml',
                                    :database_name => 'sageone_acc_uk',
                                    :username => 'nigel', 
                                    :password => 'password'}}

    proceed = args_precheck_for_action(ARGV)
    @args = @arg_processor.process_args(ARGV) if proceed
    switch_environment if @args && @args.include?("-t")
    self
  end

  def checkout_changes
    puts ""
    @apps.each do |app|
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
    @apps.each do |app|
      if File.directory?(app[0].to_s)
        Dir.chdir app[0].to_s
        pwd = Dir.pwd
        yaml = "#{pwd}/#{app[1][:yml_location]}"
        config = YAML.load ERB.new(IO.read(yaml)).result
        config[@args["-t"]]["database"]  = app[1][:database_name]
        File.open(app[1][:yml_location],'w') do |h| 
          h.write config.to_yaml
        end
          status = `git status`
          puts "#{app[0]}/#{app[1][:yml_location]}" if status.include?("database.yml")
        Dir.chdir ".."
      end
    end
    puts ""
  end

  def defaults
    @apps.each do |app|
    puts app[0]
    puts "Database: #{ app[1][:database_name]}"
    puts "Username: #{ app[1][:username]}"
    puts "Password: #{ app[1][:password]}"
    puts ""
    end
  end

  def sage_apps_in_pwd
    Dir.glob('*').select {|f| puts f if sage_app? f}
  end

 private


 def colorize(text, color_code)
   "\e[#{color_code}m#{text}\e[0m"
 end

 def print_help
   system( "clear")
   puts ""
   puts colorize("**********************************************************************************************************",32)
   puts colorize("**********************************************************************************************************",32)
   puts colorize("**",32) + colorize("                          This tool configures database settings for the                              ",31) + colorize("**",32)
   puts colorize("**",32) + colorize("                          environment you are targeting.                                              ",31) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          To use run",33) + " 'ruby db_connect.rb'" + colorize(" in the same                                 ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                          directory as your Sage one apps.                                            ",33) + colorize("**",32)
   puts colorize("**",32) + colorize("                                                                                                      ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Use the following switches to pass arguments                                ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -t <host>          [",36) + colorize("required",31) + colorize("]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -d <database name> [optional]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -u <username>      [optional]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          -p <password>      [optional]                                               ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          e.g. -t test                                                                ",36) + colorize("**",32)
   puts colorize("**",32) + colorize("                          Valid hosts are 'test' and 'development'                                    ",36) + colorize("**",32)
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
      @apps.each do |app| 
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

class ArgumentProcessor
 def initialize
   @switches = {"-h" => "help", "-t" => "host", "-d" => "database", "-u" => "username", "-p" => "password"}
   @cammands = {"--revert", "--default", -"-help", "-h"}
 end
 
 def args_precheck_for_action(args)
   if args.include?("--revert")
     checkout_changes
   end
   if args.empty? || args.include?('-h') || args.include?('--help')
     print_help
   end
   if args.include? '--default'
     defaults
   end
  ( args.empty? || args.include?('--default')) ? false : true
 end

 def process_args(args)
   values = {}
   values[:errors] = []
   state = :searching
   switch = nil
   binding.pry
   if @commands.include?(args) || args.empty?
     values[:switch] = args[0]
     state = :end
   end
   args.each do |arg|
     case state

     when :reading
       values[switch] = arg
       state = :searching
     when :searching
       if @switches.include?(arg)
         state = :reading
         switch = arg
       else
         values[:errors] << 'missing switch' 
         state = :error
       end
     when :error
       return values
     end
   end if state != :end
 values
 end

end
args_processor = ArgumentProcessor.new
configurator = DatabaseConfig.new(args_processor)
#configurator.switch_environment
#dc.sage_apps_in_pwd
#configurator.checkout_changes

