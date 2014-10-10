require 'spec_helper'

include QDisk

describe QDisk::Query do

  let(:info) do
    set_process_output('dump')
    QDisk::Info.new
  end

  describe :find_disks do

    it 'should find mounted removable usb disks' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      found.length.should eq(1)
      found = found.first
      found.device_name.should eq('/dev/sdb')
      found.interface.should eq('usb')
      found.should_not be_mounted
      found.partitions.first.should be_mounted
    end

  end

  describe :find_partitions do
    xit "should be tested"
  end

end
