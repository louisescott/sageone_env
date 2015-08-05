require_relative 'lib/argument_processor.rb'
require_relative 'lib/database_config_updater.rb'

args_processor = ArgumentProcessor.new
configurator = DatabaseConfigUpdater.new(args_processor, ARGV)
