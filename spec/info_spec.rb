require 'spec_helper'

describe QDisk::Info do

  it 'should load information' do
    set_process_output('dump')
    QDisk::Info.load.should_not be_nil
  end

  it 'should load information about each disk' do
    set_process_output('dump')
    QDisk::Info.load.length.should == 11
  end

end
