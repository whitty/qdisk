require 'spec_helper'

describe QDisk::DiskUtil::Info do

  let(:info) do
    stub_commands('spec/sample/diskutil/1')
    QDisk::DiskUtil::Info.new
  end

  it 'should load information using udisk --dump' do
    stub_commands('spec/sample/diskutil/1')
    allow(QDisk).to receive(:run) {|*x| p x; nil }
    QDisk::DiskUtil::Info.new.should_not be_nil
  end

  it 'should load information about each disk' do
    stub_commands('spec/sample/diskutil/1')
    QDisk::DiskUtil::Info.new.disks.length.should == 4
  end

  it 'should load information about each partition' do
    stub_commands('spec/sample/diskutil/1')
    QDisk::DiskUtil::Info.new.partitions.length.should == 6
  end

  describe QDisk::DiskUtil::Info::Disk do

    it 'should load information about each disk' do
      disk = info.disks.first
      #disk.get('device').should eq('8:0')
      disk.get('device-file').should eq('/dev/disk0')
      disk.get(:device_file, 'by-id').should be_an(Array)
      disk.get(:device_file, 'by-id').should be_empty #include('/dev/disk/by-id/wwn-0x5000cca644ebaff9')
      disk.should_not be_mounted
      disk.should_not be_removable
      disk.interface.should eq('ata')
      disk.partitions.length.should eq(3)
    end

  end

end
