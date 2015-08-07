require 'spec_helper'
require 'argument_processor.rb'

describe ArgumentProcessor do
  describe 'process_args' do
    context 'when no arguments are passed' do
      it 'expects the help switch to be included in the return' do
        expect(subject.process_args([])).to eq({:switches =>{},:commands=>["--help"],:errors=>[]})
      end
    end
    context 'when an invalid argument is passed' do
      it 'expects values to include an error in the return' do
        expect(subject.process_args(["-z"])).to eq({:commands=>["--help"],:switches=>{},:errors=>["invalid switch"]})
      end
    end
    context 'when a valid argument is passed' do
      it 'expects values to include the correct switch and value in the return' do
        expect(subject.process_args(["-t","test"])).to eq({:commands=>[],:switches=>{"-t"=>"test"},:errors=>[]})
      end
    end
    context 'when 2 valid arguments are passed' do
      it 'expects values to include the correct switches and values in the return' do
        expect(subject.process_args(["-t","test","-d","my_database"])).to eq({:commands=>[],:switches=>{"-t"=>"test","-d"=> "my_database"},:errors=>[]})
      end
    end
  end
end
