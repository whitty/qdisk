require 'spec_helper'

include QDisk

describe :actions do

  describe :unmount do

    context "against real captured dump data" do
      include_context "against real captured dump data"

      it "should unmount each partition of found disk" do
        QDisk.should_receive(:unmount_partition)
        unmount(:query => [:removable?, [:interface, 'usb'], :mounted?])
      end

      it "should unmount each partition of found disk (hash args)" do
        QDisk.should_receive(:unmount_partition)
        unmount({:query => [:removable?, [:interface, 'usb'], :mounted?]})
      end

      it "should unmount each partition of found disk and detach" do
        QDisk.should_receive(:unmount_partition)
        QDisk.should_receive(:detach_disk)
        unmount(:query => [:removable?, [:interface, 'usb'], :mounted?], :detach => true)
      end

      it "should unmount each partition (2) of found disk and detach" do
        QDisk.should_receive(:unmount_partition).twice
        QDisk.should_receive(:detach_disk)
        unmount(:query => [[:interface, 'ata'], :mounted?], :detach => true)
      end

      it "should should perform no action if :no_act specified " do
        unmount(:query => [[:interface, 'ata'], :mounted?], :detach => true, :no_act => true)
      end

      it "should should perform no action if :no_act specified " do
        out, _ = capture_output do
          unmount(:query => [[:interface, 'ata'], :mounted?], :detach => true, :no_act => true, :verbose => true)
        end
        out.should match(/udisks.*--unmount.*\/dev\/sda5/)
        out.should match(/udisks.*--unmount.*\/dev\/sda6/)
        out.should match(/udisks.*--detach.*\/dev\/sda/)
      end

      it "should error with NotUnique if more than one disk is found" do
        expect {unmount(:query => [[:interface, 'usb'], :mounted?], :detach => true, :only => true)}.to raise_error(NotUnique)
      end

      it "should error with NotUnique if more than one disk is found (:only)" do
        expect {unmount(:query => [[:interface, 'usb'], :mounted?], :detach => true, :only => true)}.to raise_error(NotUnique)
      end

      it "should unmount each partition of each found disk (2) if --multi provided" do
        QDisk.should_receive(:unmount_partition).twice
        QDisk.should_receive(:detach_disk).twice
        unmount(:query => [[:interface, 'usb'], :mounted?], :detach => true, :multi => true)
      end

      it "should error with NotFound no disk is found" do
        expect {unmount(:query => [[:interface, 'ps2'], :mounted?], :detach => true, :only => true)}.to raise_error(NotFound)
      end

    end

    context "whole-disk filesystem (no partition)" do

      let(:info) do
        QDisk::Info.new
      end

      it 'should find just the disk if mounted and no partitions' do
        set_process_output('loop-dump')
        QDisk.should_receive(:unmount_partition)
        unmount(:query => [ [:interface, 'loop'], :mounted?], :no_act => true)
      end

      it 'should find just the disk if mounted and no partitions' do
        set_process_output('loop-dump')
        QDisk.should_receive(:unmount_partition)
        QDisk.should_receive(:detach_disk)
        unmount(:query => [ [:interface, 'loop'], :mounted?], :detach => true, :no_act => true)
      end

      it 'should find just the disk if mounted and no partitions (output)' do
        set_process_output('loop-dump')
        out, _ = capture_output do
          unmount(:verbose => true, :query => [ [:interface, 'loop'], :mounted?], :detach => true, :no_act => true)
        end
        out.should match(/udisks.*--unmount.*\/dev\/loop0/)
        out.should match(/udisks.*--detach.*\/dev\/loop0/)
      end
    end

  end

  describe :cp do

    context "against real captured dump data" do
      include_context "against real captured dump data"

      it "calls FileUtils.cp with arguments to destination path" do
        FileUtils.should_receive(:cp).with(['a', 'b'], Pathname('/media/CANON_DC'), anything)
        cp(['a', 'b', '.'], :query => [:removable?, [:interface, 'usb'], :mounted?])
      end

      it "calls FileUtils.cp with arguments to destination path with subdir" do
        FileUtils.should_receive(:cp).with(['a', 'b'], Pathname('/media/CANON_DC/data'), anything)
        cp(['a', 'b', 'data'], :query => [:removable?, [:interface, 'usb'], :mounted?])
      end

      it "calls FileUtils.cp with arguments to destination path with relative dir" do
        FileUtils.should_receive(:cp).with(['a', 'b'], Pathname('/media'), anything)
        cp(['a', 'b', '..'], :query => [:removable?, [:interface, 'usb'], :mounted?])
      end

      it "calls FileUtils.cp with single argument to new file-name" do
        FileUtils.should_receive(:cp).with('a', Pathname('/media/CANON_DC/b'), anything)
        cp(['a', 'b'], :query => [:removable?, [:interface, 'usb'], :mounted?])
      end

      it 'use cp ::noop with --no-act' do
        FileUtils.should_receive(:cp).with('a', Pathname('/media/CANON_DC/b'), hash_including(:noop => true))
        cp(['a', 'b'], :query => [:removable?, [:interface, 'usb'], :mounted?], :no_act => true)
      end

    end

    context "whole-disk filesystem (no partition)" do

      let(:info) do
        QDisk::Info.new
      end

      it 'should find just the disk if mounted and no partitions' do
        set_process_output('loop-dump')
        FileUtils.should_receive(:cp).with('a', Pathname('/mnt/b'), hash_including(:noop => true))
        cp(['a', 'b'], :query => [ [:interface, 'loop'], :mounted?], :no_act => true)
      end

    end

    it "Missing argument 1" do
      expect { cp([], :query => [:removable?, [:interface, 'usb'], :mounted?]) }.to raise_error(QDisk::MissingRequiredArgument)
    end

    it "Missing argument 2" do
      expect { cp(['a'], :query => [:removable?, [:interface, 'usb'], :mounted?]) }.to raise_error(QDisk::MissingRequiredArgument)
    end

  end

  describe :unmount_partition do

    context "against real captured dump data" do
      include_context "against real captured dump data"

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

  describe :mount_partition do

    context "against real captured dump data" do
      include_context "against real captured dump data"

      it 'should mount unmounted removable usb disk partition' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb']] })
        set_process_output('mount')
        mount_partition(found.first.partitions.first).should be(true)
      end

      it 'should raise exception when mounting non-existent partition' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb']] })
        set_process_failure('mount-non', 1)
        expect { mount_partition(found.first.partitions.first) }.to raise_error(QDisk::MountFailed)
      end

      it 'should not raise exception when mounting already mounted partition' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb']] })
        set_process_failure('mount-already', 1)
        mount_partition(found.first.partitions.first).should be(true)
      end
    end

    let(:part) do
      double('QDisk::Info::Partition')
    end

    it 'runs invokes udisks --mount <device_name>' do
      expect(part).to receive(:device_name).and_return('/dev/foo1')
      expect(QDisk).to receive(:run).with(%w{udisks --mount /dev/foo1}, anything).and_return([double_status(0),''])
      mount_partition(part)
    end

    it 'runs doesn\'t invoke udisk if --no_act specified' do
      expect(part).to receive(:device_name).and_return('/dev/foo1')
      mount_partition(part, :no_act => true)
      expect(QDisk).not_to receive(:run)
    end

    it 'emits commandline if --verbose specified' do
      expect(part).to receive(:device_name).and_return('/dev/foo1')
      expect(QDisk).to receive(:run).with(%w{udisks --mount /dev/foo1}, hash_including(:verbose => true)).and_return([double_status(0),''])
      mount_partition(part, :verbose => true)
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

    context "against real captured dump data" do
      include_context "against real captured dump data"

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

  describe :wait do

    let(:info) do
      double(QDisk::Info)
    end

    it 'should return quickly if query is true' do
      set_process_output('dump')
      start = Time.now
      Timeout::timeout(10) do
        wait([], {:query => [:removable?, [:interface, 'usb'], :mounted?] }).should_not be(false)
      end
      end_time = Time.now
      (end_time - start).should be < 0.2
    end

    it 'should return after timeout if query is false', :slow => true do
      IO.should_not receive(:popen)
      allow(QDisk::Info).to receive(:new).and_return(info)
      expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times
      expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times
      start = Time.now
      wait([], {:timeout => 0.5, :query => [:removable?, [:interface, 'badint'], :mounted?] }).should be(false)
      end_time = Time.now
      elapsed = end_time - start
      (0.5 - elapsed).abs.should be < 0.1
    end

    it 'should return before timeout if query becomes true', :slow => true do
      IO.should_not receive(:popen)
      allow(QDisk::Info).to receive(:new).and_return(info)
      expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times
      expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([])
      partition = double(QDisk::Info::Partition)
      expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([partition])
      start = Time.now
      wait([], {:timeout => 1.0, :query => [:removable?, [:interface, 'badint'], :mounted?] })#.should be(false)
      end_time = Time.now
      elapsed = end_time - start
      elapsed.should be < 0.5
    end

    context ":mount option" do

      it 'should query looking for mount candidates if query is false', :slow => true do
        IO.should_not receive(:popen)
        QDisk.should_not receive(:mount_partition)

        allow(QDisk::Info).to receive(:new).and_return(info)
        expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times
        expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times

        # expected additional queries (not mounted, but usage is filesystem)
        expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint'], [:usage, "filesystem"]] }).and_return([]).at_least(2).times
        expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], [:usage, "filesystem"]] }).and_return([]).at_least(2).times

        start = Time.now
        wait([], {:timeout => 0.5, :mount => true, :query => [:removable?, [:interface, 'badint'], :mounted?] }).should be(false)
        end_time = Time.now
        elapsed = end_time - start
        (0.5 - elapsed).abs.should be < 0.1
      end

      it 'should attempt to mount if query is false, but a similar result matches one', :slow => true do
        allow(QDisk::Info).to receive(:new).and_return(info)
        expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times
        expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], :mounted?] }).and_return([]).at_least(2).times

        partition = double(QDisk::Info::Partition)

        # expected additional queries (not mounted, but usage is filesystem)
        expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint'], [:usage, "filesystem"]] }).and_return([]).at_least(2).times
        expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint'], [:usage, "filesystem"]] }).and_return([partition]).at_least(2).times

        # Expect attempt wil be made to mount
        QDisk.should_receive(:mount_partition).with(partition, anything)
        expect(partition).to receive(:device_name).and_return('/dev/sdd1')

        start = Time.now
        out, _ = capture_output do
          wait([], {:timeout => 1.5, :mount => true, :query => [:removable?, [:interface, 'badint'], :mounted?] }).should be(false)
        end
        end_time = Time.now
        elapsed = end_time - start
        (1.5 - elapsed).abs.should be < 0.1

        out.should eq("Attempt to mount /dev/sdd1\n")
      end

      it 'should not look for mount options if mounted? not specified', :slow => true do
        IO.should_not receive(:popen)
        QDisk.should_not receive(:mount_partition)

        allow(QDisk::Info).to receive(:new).and_return(info)
        expect(QDisk).to receive(:find_disks).with(info, {:query => [:removable?, [:interface, 'badint']] }).and_return([]).at_least(2).times
        expect(QDisk).to receive(:find_partitions).with(info, {:query => [:removable?, [:interface, 'badint']] }).and_return([]).at_least(2).times

        start = Time.now
        wait([], {:timeout => 0.5, :mount => true, :query => [:removable?, [:interface, 'badint']] }).should be(false)
        end_time = Time.now
        elapsed = end_time - start
        (0.5 - elapsed).abs.should be < 0.1
      end

    end

  end

end
