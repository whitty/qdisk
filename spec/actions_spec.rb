require 'spec_helper'

include QDisk

describe :actions do

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

  describe :unmount do

    it "should unmount each partition of found disk" do
      set_process_output('dump')
      QDisk.should_receive(:unmount_partition)
      unmount(:query => [:removable?, [:interface, 'usb'], :mounted?])
    end

    it "should unmount each partition of found disk" do
      set_process_output('dump')
      QDisk.should_receive(:unmount_partition)
      unmount({:query => [:removable?, [:interface, 'usb'], :mounted?]})
    end

    it "should unmount each partition of found disk and detach" do
      set_process_output('dump')
      QDisk.should_receive(:unmount_partition)
      QDisk.should_receive(:detach_disk)
      unmount(:query => [:removable?, [:interface, 'usb'], :mounted?], :detach => true)
    end

    xit "should redo tests above, but verify arguments" do
      false.should be(true)
    end

    xit "should redo tests with multiple disks matching query" do
      false.should be(true)
    end

    xit "should redo tests with multiple disks matching query and :only" do
      false.should be(true)
    end

    xit "should redo tests with no disks matching query" do
      false.should be(true)
    end

  end

  describe :unmount_partition do

    it 'should unmount mounted removable usb disk partition' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_output('unmount')
      unmount_partition(found.first.partitions.first).should be(true)
    end

    it 'should raise exception when unmounting non-existent partition' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_failure('mount-non', 1)
      expect { unmount_partition(found.first.partitions.first) }.to raise_error(QDisk::UnmountFailed)
    end

    it 'should not raise exception when unmounting already unmounted partition' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_failure('unmount-already', 1)
      unmount_partition(found.first.partitions.first).should be(true)
    end

    xit 'run with --no-act' do
      false.should be(true)
    end

  end

  describe :detach_disk do

    it 'should detach removable usb disk' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_output('detach-sdb')
      detach_disk(found.first).should be(true)
    end

    it 'should raise exception when detaching non-existent drive' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_failure('mount-non', 1)
      expect { detach_disk(found.first) }.to raise_error(QDisk::DetachFailed)
    end

    it 'should raise exception when detaching drive with still mounted partitions' do
      pending("need output for detach-still-mounted failure")
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_failure('detach-still-mounted', 1)
      expect { detach_disk(found.first) }.to raise_error(QDisk::DetachFailed)
    end

    xit 'run with --no-act' do
      false.should be(true)
    end

  end

end
