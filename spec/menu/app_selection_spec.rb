require 'spec_helper'
require 'app_selection.rb'

describe 'initialisation' do
  let(:app) { {:test => {:database => 'mydatabase', :user => 'myuser', :password => 'mypassword'}}}
  let(:app_selection) {AppSelection.new(app)}

  before :each do
    allow(app_selection).to receive(:prompt).and_return("1")
  end

  context 'when the correct options are passed in' do
    it 'expects an instance variable is set to equal the argument' do
      expect(app_selection.instance_variable_get(:@app_defaults)).to eql(app)
    end
  end
  context 'when no options are passed in' do
    it 'expects an exception to be raised' do
      expect{ AppSelection.new(nil) }.to raise_error(ArgumentError)
    end
  end

  describe 'get_user_app_selection' do
    context 'when a request for a user app selection is made' do 
      it 'expects an options menu to be shown' do
      end

      it 'expects the show_options_menu method to be called' do
        expect(app_selection).to receive(:show_options_menu)
        app_selection.request_user_app_selection
      end
      it 'expects STDOUT to receive output' do
        expect { app_selection.request_user_app_selection }.to output.to_stdout
      end
      it 'expects the prompt_user_for_selection method to be called' do
        app_selection.request_user_app_selection
      end
      it 'expects the process_user_response method to be called' do
        expect(app_selection).to receive(:process_user_response)
        app_selection.request_user_app_selection
      end
    end
  end
end
