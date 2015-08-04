require 'yaml'
require "erb"
require 'pry'

class ArgumentProcessor

 def initialize
   @switches = {"-t" => "host", "-d" => "database", "-u" => "username", "-p" => "password"}
   @commands = ["--revert", "--default", "--help", "-h"]
 end
 
 def process_args(args)
   values = {:commands => [], :switches => {}}
   values[:errors] = []
   state = :searching
   switch = nil

   if args.empty?
     values[:commands] << "--help"
     state = :end
   elsif
     args.each do |arg|
       if @commands.include?(arg)
         values[:commands] << arg
         state = :end
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
         values[:errors] << 'missing switch' 
         values[:commands] << "--help"
         state = :error
       end
     when :error
       return values
     end
   end if state != :end
 values
 end

end
