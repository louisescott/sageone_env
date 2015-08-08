require 'spec_helper'
require 'database_config_updater.rb'

describe DatabaseConfigUpdater do
  before :each do
    allow(File).to receive(:directory?).and_return true
    allow(Dir).to receive(:chdir)
    allow_any_instance_of(DatabaseConfigUpdater).to receive(:print_errors).and_return(true)
    allow_any_instance_of(DatabaseConfigUpdater).to receive(:print_help).and_return(true)
  end
  describe 'initialize' do
    context 'when no arg_processor is passed to the method' do
      it 'expects nil' do
        arg_processor = nil
        expect{DatabaseConfigUpdater.new(arg_processor,[])}.to raise_error(ArgumentError)
      end
    end
    context 'when a valid arg_processor is passed to the method' do
        it "expects 'load_config_defaults' to be called" do
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:load_config_defaults)
          DatabaseConfigUpdater.new(arg_processor,[])
        end
      context "and the switch is '--help'" do
        it "expects 'print_help' to be called" do
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:print_help)
          DatabaseConfigUpdater.new(arg_processor,["--help"])
        end
      end
      context "and an invalid switch is supplied" do
        it "expects 'print_help' to be called" do
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:print_help)
          DatabaseConfigUpdater.new(arg_processor,["-z"])
        end
        it "expects print_errors to be called" do
          arg_processor = ArgumentProcessor.new
          expect_any_instance_of(DatabaseConfigUpdater).to receive(:print_errors)
          DatabaseConfigUpdater.new(arg_processor,["-z"])
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
        context 'and the -e switch is also present' do
          it "expects 'switch_environment' method to be called" do
            arg_processor = ArgumentProcessor.new
            expect_any_instance_of(DatabaseConfigUpdater).to receive(:switch_environment)
            DatabaseConfigUpdater.new(arg_processor,["-t","my-uat-build","-e","test"])
          end
          it "expects 'configure_yaml_settings' method to be called for each app" do
            arg_processor = ArgumentProcessor.new
            expect_any_instance_of(DatabaseConfigUpdater).to receive(:configure_yaml_settings).exactly(6).times
            DatabaseConfigUpdater.new(arg_processor,["-t","my-uat-build","-e","test"])
          end
        end
        context 'and the -e switch is not present' do
          it "expects 'switch_environment' method not to be called" do
            arg_processor = ArgumentProcessor.new
            expect_any_instance_of(DatabaseConfigUpdater).to_not receive(:switch_environment)
            DatabaseConfigUpdater.new(arg_processor,["-t","my-uat-build"])
          end
        end
      end
    end
  end
end
