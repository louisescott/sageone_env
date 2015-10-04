require 'yaml'

class ArgumentProcessor

 def initialize
   @switches = {"-e" => "environment", "-h" => "help", "-t" => "host", "-d" => "database", "-u" => "username", "-p" => "password"}
   @commands = ["--set_defaults", "--detect_apps","--revert", "--defaults", "--help", "-h"]
 end

 def process_args(args)
   values = {:commands => [], :switches => {}}
   values[:errors] = []
   state = :searching
   switch = nil

   if args.empty?
     values[:commands] << "--help"
     state = :end
   else
     args.each do |arg|
       if @commands.include?(arg)
         values[:commands] << arg
         #state = :end
       end
     end
   end

   args.each do |arg|
     case state
     when :reading
       values[:switches][switch] = arg
       state = :searching
     when :searching
       if @switches.include?(arg)
         state = :reading
         switch = arg
       else
         unless  @commands.include?(arg)
           values[:errors] << "invalid switch #{arg}"
           values[:commands] << "--help"
          # state = :error
         end
       end
     when :error
       return values
     end
   end if state != :end
 values
 end
end
