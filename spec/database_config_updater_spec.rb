require 'spec_helper'
require 'pry'
require 'database_config_updater.rb'

describe DatabaseConfigUpdater do
  describe 'initialize' do
    context 'when no arg_processor is passed to the method' do
      it 'expects nil' do 
        arg_processor = nil
        expect{DatabaseConfigUpdater.new(arg_processor,[])}.to raise_error(ArgumentError)
      end
    end
    context 'when a valid arg_processor is passed to the method' do
      context "and the switch is '--help'" do
        it "expects 'print_help' to be called" do 
          help_text = File.read('spec/help.txt')
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:print_help)
          DatabaseConfigUpdater.new(arg_processor,["--help"])
        end
      end
      context "and the switch is '--default'" do
        it "expects the 'defaults' method to be called" do 
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:defaults)
          DatabaseConfigUpdater.new(arg_processor,["--default"])
        end
      end
      context "and the switch is '--revert'" do
        it "expects the 'checkout_changes' method to be called" do 
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:checkout_changes)
          DatabaseConfigUpdater.new(arg_processor,["--revert"])
        end
      end
      context "and the switch is '-t'" do
        it "expects 'switch_environment' method to be called" do 
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:switch_environment)
          DatabaseConfigUpdater.new(arg_processor,["-t","test"])
        end
      end
    end
  end
end
