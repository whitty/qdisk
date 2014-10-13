require 'spec_helper'

describe QDisk::Info do

  let(:info) do
    set_process_output('dump')
    QDisk::Info.new
  end

  it 'should load information using udisk --dump' do
    set_process_output('dump')
    QDisk::Info.new.should_not be_nil
  end

  it 'should load information about each disk' do
    set_process_output('dump')
    QDisk::Info.new.disks.length.should == 4
  end

  it 'should load information about each partition' do
    set_process_output('dump')
    QDisk::Info.new.partitions.length.should == 9
  end

  describe QDisk::Info::Disk do

    it 'should load information about each disk' do
      disk = info.disks.first
      disk.get('device').should eq('8:0')
      disk.get('device-file').should eq('/dev/sda')
      disk.get(:device_file, 'by-id').should be_an(Array)
      disk.get(:device_file, 'by-id').should include('/dev/disk/by-id/wwn-0x5000cca644ebaff9')
      disk.should_not be_mounted
      disk.should_not be_removable
      disk.interface.should eq('ata')
      disk.partitions.length.should eq(7)
    end

    it 'should load information about each disk' do
      disk = info.disks.last
      disk.get('device').should eq('11:0')
      disk.get('device-file').should eq('/dev/sr0')
      disk.get(:device_file, 'by-id').should eq('/dev/disk/by-id/ata-MATSHITADVD-RAM_UJ8B0_YN46_173191')
      disk.should_not be_mounted
      disk.should be_removable
      disk.interface.should eq('scsi')
      disk.partitions.length.should eq(0)
    end

    it 'should load information about each disk' do
      disk = info.disks[1]
      disk.get('device').should eq('8:16')
      disk.get('device-file').should eq('/dev/sdb')
      disk.get(:device_file, 'by-id').should eq('/dev/disk/by-id/usb-Multiple_Card_Reader_058F63666435-0:0')
      disk.should_not be_mounted
      disk.should be_removable
      disk.interface.should eq('usb')
      disk.partitions.length.should eq(1)
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

  describe QDisk::Info::Partition do

    it 'should load information about each partition' do
      disk = info.disks[1]
      disk.partitions.length.should eq(1)
      part = disk.partitions.first
      part.get('device').should eq('8:17')
      part.get('device-file').should eq('/dev/sdb1')
      part.get(:device_file, 'by-id').should be_an(Array)
      part.get('device_file', 'by-id').should include(disk.get('device_file', 'by-id') + '-part1')
      part.should be_mounted
    end

    it "should have different states mounted and unmounted" do
      set_process_output('show-info-sdb1-not-mounted')
      i = QDisk::Info.new
      part = i.partition('/dev/sdb1')
      part.should_not be_nil
      part.should_not be_mounted

      set_process_output('show-info-sdb1')
      i = QDisk::Info.new
      part = i.partition('/dev/sdb1')
      part.should_not be_nil
      part.should be_mounted
      part.mount_paths.should eq('/media/CANON_DC')
      part.mounted_by_uid.should eq('1000')
    end

    it "should include the first matching data" do
      set_process_output('show-info-sdb1')
      i = QDisk::Info.new
      part = i.partition('/dev/sdb1')
      part.uuid.should eq('5D9F-38E7')
      part.label.should eq('CANON_DC')
      part.type.should eq('vfat')
    end

  end

  describe "queries" do
    it "should query based on removability" do
      result = info.query_disks(:removable?)
      result.should be_an(Array)
      result.length.should eq(2)
      result.first.interface.should eq('usb')
      result.last.interface.should eq('scsi')

      result = info.query_partitions(:removable?)
      result.should be_an(Array)
      result.length.should eq(0)
    end

    it "should query based on mounted?" do
      result = info.query_disks(:mounted?)
      result.should be_an(Array)
      result.length.should eq(0)

      result = info.query_partitions(:mounted?)
      result.should be_an(Array)
      result.length.should eq(4)
      result.first.mount_paths.should eq('/')
      result.last.mount_paths.should eq('/media/ED3C-74EC')
    end

    it "should query based on interface?" do
      result = info.query_disks(:interface, 'scsi')
      result.should be_an(Array)
      result.length.should eq(1)

      result = info.query_disks(:interface, 'usb')
      result.should be_an(Array)
      result.length.should eq(2)

      result = info.query_disks(:interface, 'ata')
      result.should be_an(Array)
      result.length.should eq(1)

      result = info.query_disks(:interface, 'other')
      result.should be_an(Array)
      result.length.should eq(0)

      result = info.query_partitions(:interface, 'scsi')
      result.should be_an(Array)
      result.length.should eq(0)

    end

  end

end
