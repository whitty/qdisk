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
      disk.should_not be_read_only
      disk.should_not be_removable
      disk.interface.should eq('ata')
      disk.partitions.length.should eq(3)
    end

    it 'should load information about each disk' do
      disk = info.disks.last
      #disk.get('device').should eq('11:0')
      disk.get('device-file').should eq('/dev/disk3')
      disk.get(:device_file, 'by-id').should be_empty # eq('/dev/disk/by-id/ata-MATSHITADVD-RAM_UJ8B0_YN46_173191')
      disk.should_not be_mounted
      disk.should_not be_read_only
      disk.should be_removable
      disk.interface.should eq('usb')
      disk.partitions.length.should eq(1)
    end

    it 'should load information about each disk' do
      disk = info.disks[1]
      disk.get('device-file').should eq('/dev/disk1')
      disk.get(:device_file, 'by-id').should be_empty #eq('/dev/disk/by-id/usb-Multiple_Card_Reader_058F63666435-0:0')
      disk.should be_mounted
      disk.should_not be_removable
      disk.should_not be_read_only
      disk.interface.should eq('ata')
      disk.partitions.length.should eq(0)
    end

    it 'should load information about each disk' do
      disk = info.disks[2]
      disk.get('device-file').should eq('/dev/disk2')
      disk.get(:device_file, 'by-id').should be_empty #eq('/dev/disk/by-id/usb-Multiple_Card_Reader_058F63666435-0:0')
      disk.should_not be_mounted
      disk.should be_read_only
      disk.should be_removable
      disk.interface.should eq('loop')
      disk.partitions.length.should eq(2)
    end

    it "should give equivalent mappings for different query formats" do
      disk = info.disks[1]
      device = disk.device_file
      ['device_file', 'device file', 'device-file', :device_file].each do |n|
        # should all return exactly the same object
        disk.get(n).should be(device)
      end
    end

  end

  describe QDisk::DiskUtil::Info::Partition do

    it 'should load information about each partition' do
      disk = info.disks[3]
      disk.partitions.length.should eq(1)
      part = disk.partitions.first
      part.get('device-file').should eq('/dev/disk3s1')
      part.should be_mounted

      part.uuid.should eq('5F3610D1-B489-376E-B59C-7C178A5E5640')
      part.label.should eq('SHOGUN')
      part.type.should eq('exfat')
    end

    it "should have different states mounted and unmounted" do
      stub_commands('spec/sample/diskutil/1_disk3s1_not_mounted')
      i = QDisk::DiskUtil::Info.new
      part = i.partition('/dev/disk3s1')
      part.should_not be_nil
      part.should_not be_mounted

      stub_commands('spec/sample/diskutil/1')
      i = QDisk::DiskUtil::Info.new
      part = i.partition('/dev/disk3s1')
      part.should_not be_nil
      part.should be_mounted
      part.mount_paths.should eq('/Volumes/SHOGUN')
    end

  end


  describe "queries" do
    it "should query based on removability" do
      result = info.query_disks(:removable?)
      result.should be_an(Array)
      result.length.should eq(2)
      result.first.interface.should eq('loop')
      result.last.interface.should eq('usb')

      result = info.query_partitions(:removable?)
      result.should be_an(Array)
      result.length.should eq(0)
    end

    it "should query based on mounted?" do
      result = info.query_disks(:mounted?)
      result.should be_an(Array)
      result.length.should eq(1)
      result.first.mount_paths.should eq('/')
      result.first.device_name.should eq('/dev/disk1')

      result = info.query_partitions(:mounted?)
      result.should be_an(Array)
      result.length.should eq(2)
      result.first.mount_paths.should eq('/Volumes/VirtualBox')
      result.last.mount_paths.should eq('/Volumes/SHOGUN')
    end

    it "should query based on interface" do
      result = info.query_disks(:interface, 'scsi')
      result.should be_an(Array)
      result.length.should eq(0)

      result = info.query_disks(:interface, 'usb')
      result.should be_an(Array)
      result.length.should eq(1)
      result.first.device_name.should eq('/dev/disk3')

      result = info.query_disks(:interface, 'ata')
      result.should be_an(Array)
      result.length.should eq(2)
      result.first.device_name.should eq('/dev/disk0')
      result.last.device_name.should eq('/dev/disk1')

      result = info.query_disks(:interface, 'other')
      result.should be_an(Array)
      result.length.should eq(0)

      result = info.query_disks(:interface, 'loop')
      result.should be_an(Array)
      result.length.should eq(1)
      result.first.device_name.should eq('/dev/disk2')

      result = info.query_partitions(:interface, 'scsi')
      result.should be_an(Array)
      result.length.should eq(0)
    end

  end

end
