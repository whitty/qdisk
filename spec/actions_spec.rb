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

    it "should unmount each partition of found disk (hash args)" do
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

    it "should unmount each partition (2) of found disk and detach" do
      set_process_output('dump')
      QDisk.should_receive(:unmount_partition).twice
      QDisk.should_receive(:detach_disk)
      unmount(:query => [[:interface, 'ata'], :mounted?], :detach => true)
    end

    it "should should perform no action if :no_act specified " do
      set_process_output('dump')
      unmount(:query => [[:interface, 'ata'], :mounted?], :detach => true, :no_act => true)
    end

    it "should should perform no action if :no_act specified " do
      set_process_output('dump')
      out, _ = capture_output do
        unmount(:query => [[:interface, 'ata'], :mounted?], :detach => true, :no_act => true, :verbose => true)
      end
      out.should match(/udisks.*--unmount.*\/dev\/sda5/)
      out.should match(/udisks.*--unmount.*\/dev\/sda6/)
      out.should match(/udisks.*--detach.*\/dev\/sda/)
    end

    it "should error with NotUnique if more than one disk is found" do
      set_process_output('dump')
      expect {unmount(:query => [[:interface, 'usb'], :mounted?], :detach => true, :only => true)}.to raise_error(NotUnique)
    end

    it "should error with NotUnique if more than one disk is found (:only)" do
      set_process_output('dump')
      expect {unmount(:query => [[:interface, 'usb'], :mounted?], :detach => true, :only => true)}.to raise_error(NotUnique)
    end

    it "should unmount each partition of each found disk (2) if --multi provided" do
      set_process_output('dump')
      QDisk.should_receive(:unmount_partition).twice
      QDisk.should_receive(:detach_disk).twice
      unmount(:query => [[:interface, 'usb'], :mounted?], :detach => true, :multi => true)
    end

    it "should error with NotFound no disk is found" do
      set_process_output('dump')
      expect {unmount(:query => [[:interface, 'ps2'], :mounted?], :detach => true, :only => true)}.to raise_error(NotFound)
    end

  end

  describe :cp do

    it "calls FileUtils.cp with arguments to destination path" do
      set_process_output('dump')
      FileUtils.should_receive(:cp).with(['a', 'b'], Pathname('/media/CANON_DC'), anything)
      cp(['a', 'b', '.'], :query => [:removable?, [:interface, 'usb'], :mounted?])
    end

    it "calls FileUtils.cp with arguments to destination path with subdir" do
      set_process_output('dump')
      FileUtils.should_receive(:cp).with(['a', 'b'], Pathname('/media/CANON_DC/data'), anything)
      cp(['a', 'b', 'data'], :query => [:removable?, [:interface, 'usb'], :mounted?])
    end

    it "calls FileUtils.cp with arguments to destination path with relative dir" do
      set_process_output('dump')
      FileUtils.should_receive(:cp).with(['a', 'b'], Pathname('/media'), anything)
      cp(['a', 'b', '..'], :query => [:removable?, [:interface, 'usb'], :mounted?])
    end

    it "calls FileUtils.cp with single argument to new file-name" do
      set_process_output('dump')
      FileUtils.should_receive(:cp).with('a', Pathname('/media/CANON_DC/b'), anything)
      cp(['a', 'b'], :query => [:removable?, [:interface, 'usb'], :mounted?])
    end

    it "Missing argument 1" do
      expect { cp([], :query => [:removable?, [:interface, 'usb'], :mounted?]) }.to raise_error(QDisk::MissingRequiredArgument)
    end

    it "Missing argument 2" do
      expect { cp(['a'], :query => [:removable?, [:interface, 'usb'], :mounted?]) }.to raise_error(QDisk::MissingRequiredArgument)
    end

    it 'use cp ::noop with --no-act' do
      set_process_output('dump')
      FileUtils.should_receive(:cp).with('a', Pathname('/media/CANON_DC/b'), hash_including(:noop => true))
      cp(['a', 'b'], :query => [:removable?, [:interface, 'usb'], :mounted?], :no_act => true)
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

    let(:part) do
      double('QDisk::Info::Partition')
    end

    it 'runs invokes udisks --unmount <device_name>' do
      expect(part).to receive(:device_name).and_return('/dev/foo1')
      expect(QDisk).to receive(:run).with(%w{udisks --unmount /dev/foo1}, anything).and_return([double_status(0),''])
      unmount_partition(part)
    end

    it 'runs doesn\'t invoke udisk if --no_act specified' do
      expect(part).to receive(:device_name).and_return('/dev/foo1')
      unmount_partition(part, :no_act => true)
      expect(QDisk).not_to receive(:run)
    end

    it 'emits commandline if --verbose specified' do
      expect(part).to receive(:device_name).and_return('/dev/foo1')
      expect(QDisk).to receive(:run).with(%w{udisks --unmount /dev/foo1}, hash_including(:verbose => true)).and_return([double_status(0),''])
      unmount_partition(part, :verbose => true)
    end

  end

  describe :run do

    it 'runs commands via popen' do
      IO.should_receive(:popen).with(['echo','foo']).and_yield(command_output('unmount', 1234))
      Process.should_receive(:wait2).with(1234).and_return([1234, double(Process::Status)])
      run(['echo', 'foo'])
    end

    it 'runs commands via popen unless --no_act' do
      IO.should_not_receive(:popen)
      run(['echo', 'foo'], :no_act => true)
    end

    it 'prints nothing if not verbose via popen' do
      IO.should_receive(:popen).with(['echo','foo']).and_yield(command_output('unmount', 1234))
      Process.should_receive(:wait2).with(1234).and_return([1234, double(Process::Status)])
      out, _ = capture_output do
        run(['echo', 'foo'], :verbose => false)
      end
      out.should eq("")
    end

    it 'prints commands if verbose' do
      IO.should_receive(:popen).with(['echo','foo']).and_yield(command_output('unmount', 1234))
      Process.should_receive(:wait2).with(1234).and_return([1234, double(Process::Status)])
      out, _ = capture_output do
        run(['echo', 'foo'], :verbose => true)
      end
      out.should eq("echo foo\n")
    end

    it 'prints commands if verbose and no_act' do
      IO.should_not_receive(:popen)
      out, _ = capture_output do
        run(['echo', 'foo'], :verbose => true, :no_act => true)
      end
      out.should eq("echo foo\n")
    end

  end

  describe :detach_disk do

    it 'should detach removable usb disk' do
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
      set_process_output('detach-sdb')
      detach_disk(found.first).should be(true)
    end

    context "when process errors on failure" do

      it 'should raise exception when detaching non-existent drive' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
        set_process_failure('mount-non', 1)
        expect { detach_disk(found.first) }.to raise_error(QDisk::DetachFailed)
      end

      it 'should raise exception when detaching drive with still mounted partitions' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
        set_process_failure('detach-sdb-still-mounted', 1)
        expect { detach_disk(found.first) }.to raise_error(QDisk::DetachFailed)
      end

    end

    context "when process returns normally on failure" do

      it 'should raise exception when detaching drive with still mounted partitions' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
        set_process_output('detach-sdb-still-mounted')
        expect { detach_disk(found.first) }.to raise_error(QDisk::DetachFailed)
      end

    end

    let(:disk) do
      double('QDisk::Info::Partition')
    end

    it 'runs doesn\'t invoke udisk if --no_act specified' do
      expect(disk).to receive(:device_name).and_return('/dev/foo')
      expect(QDisk).to receive(:run).with(%w{udisks --detach /dev/foo}, hash_including(:no_act => true)).and_return([nil, nil])
      detach_disk(disk, :no_act => true)
    end

  end

end
