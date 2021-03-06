require 'spec_helper'
require 'ostruct'

include QDisk

describe QDisk::Query do

  def tie(disk, partitions, match)
    disk.object_name = disk.device_name.sub('/dev/', '/org/freedesktop/UDisks/devices/')
    disk.partitions = partitions.select {|p| p.device_name =~ match}
    disk.partitions.each do |p|
      p.parent = disk.object_name
      p.object_name = p.device_name.sub('/dev/', '/org/freedesktop/UDisks/devices/')
    end
  end

  let(:sample_data) do
    disks = [ OpenStruct.new( { :device_name => '/dev/sda', :removable? => false}),
              OpenStruct.new( { :device_name => '/dev/sdb', :removable? => true}),
              OpenStruct.new( { :device_name => '/dev/sdc', :removable? => false, :mounted? => true}),
              OpenStruct.new( { :device_name => '/dev/sdd', :removable? => false, :mounted? => true}), ]
    partitions = [ OpenStruct.new( { :device_name => '/dev/sda1', :mounted? => false}),
                   OpenStruct.new( { :device_name => '/dev/sda2', :mounted? => true}),
                   OpenStruct.new( { :device_name => '/dev/sda3', :mounted? => true}),
                   OpenStruct.new( { :device_name => '/dev/sdb1', :mounted? => false}),
                   OpenStruct.new( { :device_name => '/dev/sdb2', :mounted? => true}),
                   OpenStruct.new( { :device_name => '/dev/sdd1', :mounted? => false}), ]
    tie(disks[0], partitions, /sda[0-9]/)
    tie(disks[1], partitions, /sdb[0-9]/)
    tie(disks[2], partitions, /sdc[0-9]/)
    tie(disks[3], partitions, /sdd[0-9]/)
    [disks, partitions]
  end

  let :disks do
    sample_data[0]
  end
  let :partitions do
    sample_data[1]
  end

  describe :find_disks do

    context "against real captured dump data" do
      include_context "against real captured dump data"

      it 'should find mounted removable usb disks' do
        found = find_disks(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
        found.length.should eq(1)
        found = found.first
        found.device_name.should eq('/dev/sdb')
        found.interface.should eq('usb')
        found.should_not be_mounted
        found.partitions.first.should be_mounted
      end

      it 'should find all disks' do
        found = find_disks(info, {:query => [] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sda', '/dev/sdb', '/dev/sdc','/dev/sr0'].to_set)
      end

      it 'should find USB disks' do
        found = find_disks(info, {:query => [[:interface, 'usb']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb','/dev/sdc'].to_set)
      end

      it 'should find ATA disks' do
        found = find_disks(info, {:query => [[:interface, 'ata']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sda'].to_set)
      end

      it 'should find SCSI disks' do
        found = find_disks(info, {:query => [[:interface, 'scsi']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sr0'].to_set)
      end

      it 'should find mounted disks' do
        found = find_disks(info, {:query => [:mounted?] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb','/dev/sdc','/dev/sda'].to_set)
      end

      it 'should find mounted, removable disks' do
        found = find_disks(info, {:query => [:mounted?, :removable?] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb'].to_set)
      end

      it 'should find matching device' do
        found = find_disks(info, {:query => [[:device, '8:16']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb'].to_set)
      end

      it 'should not find matching partition' do
        found = find_disks(info, {:query => [[:device, '8:17']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should be_empty
      end

      it 'should not find matching partition' do
        found = find_disks(info, {:query => [[:usage, 'other']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should be_empty
      end

      context "bad examples due to no sample data to query" do

        it 'should find matching usage' do
          # not the best example, but there are no non-null disk usages
          found = find_disks(info, {:query => [[:usage, '']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should eq(['/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sr0'].to_set)

          found = find_disks(info, {:query => [[:usage, 'filesystem']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should be_empty
        end

        it 'should find matching type' do
          # not the best example, but there are no non-null disk types
          found = find_disks(info, {:query => [[:type, '']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should eq(['/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sr0'].to_set)

          found = find_disks(info, {:query => [[:type, 'ntfs']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should be_empty
        end

        it 'should find matching uuid' do
          # not the best example, but there are no non-null disk uuids
          found = find_disks(info, {:query => [[:uuid, '']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should eq(['/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sr0'].to_set)

          found = find_disks(info, {:query => [[:uuid, '5D9F-38E7']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should be_empty
        end

        it 'should find matching label' do
          found = find_disks(info, {:query => [[:label, '']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should eq(['/dev/sda', '/dev/sdb', '/dev/sdc', '/dev/sr0'].to_set)

          found = find_disks(info, {:query => [[:label, 'System Reserved']] })
          found_devices = found.map{|x| x.device_name}.to_set
          found_devices.should be_empty
        end

      end

    end

    let(:info) do
      double(QDisk::Info)
    end

    it 'should filter down the list by the subsets of each query' do
      expect(info).to receive(:disks).and_return(disks.to_set)
      expect(info).to receive(:query_disks).with(:removable?).and_return([disks[0], disks[2]])
      expect(info).to receive(:query_disks).with(:interface, 'usb').and_return(disks)
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'] ] })
      found.to_set.should eq([disks[0], disks[2]].to_set)
    end

    it 'should filter down the list by the subsets of each query (different subsets)' do
      expect(info).to receive(:disks).and_return(disks)
      expect(info).to receive(:query_disks).with(:removable?).and_return([disks[0], disks[2]])
      expect(info).to receive(:query_disks).with(:interface, 'usb').and_return([disks[0], disks[1]])
      found = find_disks(info, {:query => [:removable?, [:interface, 'usb'] ] })
      found.to_set.should eq([disks[0]].to_set)
    end

    it 'mounted is queried against both owning disk and partition' do
      expect(info).to receive(:disks).and_return(disks)
      expect(info).to receive(:query_disks).with(:mounted?).and_return([disks[0], disks[2]])
      expect(info).to receive(:query_partitions).with(:mounted?).and_return([partitions[0], partitions[5]])
      found = find_disks(info, {:query => [:mounted?]})
      found.to_set.should eq([disks[0], disks[2], disks[3]].to_set)
    end

    it 'should all disks if query is not mandatory and query is empty' do
      set = disks.to_set
      expect(info).to receive(:disks).and_return(set)
      find_disks(info, {:query => [] }).should eq(set)
    end

    it 'should return empty if query is mandatory and query is empty' do
      find_disks(info, {:mandatory => true, :query => [] }).should be_empty
    end

  end

  describe :find_partitions do

    context "against real captured dump data" do
      include_context "against real captured dump data"

      it 'should find mounted removable usb disks' do
        found = find_partitions(info, {:query => [:removable?, [:interface, 'usb'], :mounted?] })
        found.length.should eq(1)
        found = found.first
        found.device_name.should eq('/dev/sdb1')
        found.should be_mounted
      end

      it 'should find all disks' do
        found = find_partitions(info, {:query => [] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(["/dev/sda1",
                                 "/dev/sda2",
                                 "/dev/sda3",
                                 "/dev/sda4",
                                 "/dev/sda5",
                                 "/dev/sda6",
                                 "/dev/sda7",
                                 "/dev/sdb1",
                                 "/dev/sdc1"].to_set)
      end
      it 'should find USB disks' do
        found = find_partitions(info, {:query => [[:interface, 'usb']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb1','/dev/sdc1'].to_set)
      end

      it 'should find ATA disks' do
        found = find_partitions(info, {:query => [[:interface, 'ata']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(["/dev/sda1",
                                 "/dev/sda2",
                                 "/dev/sda3",
                                 "/dev/sda4",
                                 "/dev/sda5",
                                 "/dev/sda6",
                                 "/dev/sda7"].to_set)
      end

      # no partitions
      it 'should find SCSI disks' do
        found = find_partitions(info, {:query => [[:interface, 'scsi']] })
        found.should be_empty
      end

      it 'should find mounted disks' do
        found = find_partitions(info, {:query => [:mounted?] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(%w{/dev/sda5 /dev/sda6 /dev/sdb1 /dev/sdc1}.to_set)
      end

      it 'should find mounted, removable disks' do
        found = find_partitions(info, {:query => [:mounted?, :removable?] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb1'].to_set)
      end

      it 'should find matching device' do
        found = find_partitions(info, {:query => [[:device, '8:17']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb1'].to_set)
      end

      it 'should not find matching disk' do
        found = find_partitions(info, {:query => [[:device, '8:16']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should be_empty
      end

      it 'should find matching usage' do
        found = find_partitions(info, {:query => [[:usage, 'other']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sda7'].to_set)
      end

      it 'should find matching type' do
        found = find_partitions(info, {:query => [[:type, 'ext4']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sda5', '/dev/sda6'].to_set)
      end

      it 'should find matching uuid' do
        found = find_partitions(info, {:query => [[:uuid, '5D9F-38E7']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sdb1'].to_set)
      end

      it 'should find matching label' do
        found = find_partitions(info, {:query => [[:label, 'System Reserved']] })
        found_devices = found.map{|x| x.device_name}.to_set
        found_devices.should eq(['/dev/sda1'].to_set)
      end

    end

    let(:info) do
      double(QDisk::Info)
    end

    it 'interface is queried against both owning disk and partition' do
      disks, partitions = sample_data

      # from the set of all partitions
      expect(info).to receive(:partitions).and_return(partitions)
      # query against partitions
      expect(info).to receive(:query_partitions).with(:interface, 'usb').and_return([partitions[2], partitions[5]])
      # match also partitions, part of matching disks
      expect(info).to receive(:query_disks).with(:interface, 'usb').and_return([disks[0]])

      found = find_partitions(info, {:query => [[:interface, 'usb']]})
      found.to_set.should eq((disks[0].partitions + [partitions[5]]).to_set)
    end

    it 'removable is queried against both owning disk and partition' do
      disks, partitions = sample_data

      # from the set of all partitions
      expect(info).to receive(:partitions).and_return(partitions)
      # query against partitions
      expect(info).to receive(:query_partitions).with(:removable?).and_return([partitions[2], partitions[5]])
      # match also partitions, part of matching disks
      expect(info).to receive(:query_disks).with(:removable?).and_return([disks[1]])

      found = find_partitions(info, {:query => [:removable?]})
      found.to_set.should eq((disks[1].partitions + [partitions[2], partitions[5]]).to_set)
    end

    it 'should all disks if query is not mandatory and query is empty' do
      set = partitions.to_set
      expect(info).to receive(:partitions).and_return(set)
      find_partitions(info, {:query => [] }).should eq(set)
    end

    it 'should return empty if query is mandatory and query is empty' do
      find_partitions(info, {:mandatory => true, :query => [] }).should be_empty
    end

  end

  describe :find do

    context "against real captured dump data (with loop device)" do
      let(:info) do
        QDisk::Info.new
      end

      before(:each) do
        set_process_output('loop-dump')
      end

      it "result of 'and' query should not depend on order" do
        found1 = QDisk.find(info, :query => [[:interface, 'usb'], :mounted?])
        found2 = QDisk.find(info, :query => [:mounted?, [:interface, 'usb']])
        found1.to_set.should eq(found2.to_set)
      end

      it "should not find dev/loop0 based on 'interface=usb,mounted'" do
        found = QDisk.find_disks(info, :query => [[:interface, 'usb'], :mounted?])
        found.find {|x| x.device_name == '/dev/loop0' }.should be_nil
      end

    end

  end

end
