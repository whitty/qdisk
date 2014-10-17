require 'spec_helper'
require 'optparse'

include QDisk

describe :parse_options do

  it 'should support --help' do
    output, _ = capture_output do
      lambda { parse_options(["--help"]) }.should exit_with_code(0)
    end
    lines = output.to_s.split(/\n/)
    lines.length.should be > 5
    # ensure lines don't wrap 80 characters
    lines.any? {|x| x.length >= 80 }.should be(false)
  end

  it 'should support --verbose' do
    options,_ = parse_options(["--verbose", 'unmount'])
    options.should include(:verbose)
  end

  describe "QueryParsing" do

    def query(*args)
      options,_ = parse_options(['query', *args])
      return options
    end

    describe 'simple predicates' do
      it 'should support :removable?' do
        options = query('--query=removable')
        options[:query].should eq([:removable?])
      end
      it 'should support :mounted?' do
        options = query('--query=mounted')
        options[:query].should eq([:mounted?])
      end
      it 'should support :read_only?' do
        options = query('--query=read_only')
        options[:query].should eq([:read_only?])
      end
    end

    describe 'name=value' do
      it 'should support :interface => value' do
        options = query('--query=interface=usb')
        options[:query].should eq([[:interface, 'usb']])
      end
      it 'should support :device => value' do
        options = query('--query=device=8:16')
        options[:query].should eq([[:device, '8:16']])
      end
      it 'should support :usage => value' do
        options = query('--query=usage=filesystem')
        options[:query].should eq([[:usage, 'filesystem']])
      end
      it 'should support :type => value' do
        options = query('--query=type=ntfs')
        options[:query].should eq([[:type, 'ntfs']])
      end
      it 'should support :uuid => value' do
        options = query('--query=uuid=A634EED434EEA691')
        options[:query].should eq([[:uuid, 'A634EED434EEA691']])
      end
      it 'should support :label => value' do
        options = query('--query=label=system reserved')
        options[:query].should eq([[:label, 'system reserved']])
      end
    end

    context "special cases" do
      it 'should parse readonly as :read_only?' do
        options = query('--query=readonly')
        options[:query].should eq([:read_only?])
      end
    end

    it 'should fail on unknown query' do
      output, _ = capture_output do
        expect {query('--query=badinterface=usb') }.to raise_error(OptionParser::InvalidArgument)
      end
      output.should match(/invalid argument.*badinterface=usb/)
    end

    describe "--best" do
      it "should add result of derive_best into query" do
        expect(QDisk).to receive(:derive_best).and_return([:mounted?])
        options = query('--best')
        options[:query].should eq([:mounted?])
      end

      it "should insert result of derive_best into query in argument order" do
        expect(QDisk).to receive(:derive_best).and_return([:mounted?])
        options = query('--query=readonly', '--best', '--query=interface=ata,device=1:2')
        options[:query].should eq([:read_only?, :mounted?, [:interface, 'ata'], [:device, '1:2']])
      end
    end

  end

end

describe :derive_best do

  let :env do
    { 'HOME' => '/home/user'}
  end

  before :each do
    stub_const "ENV", env
  end

  it "should look in home directory for .qdisk" do
    expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_raise(Errno::ENOENT)
    derive_best
  end

  context "QDISK_BEST not set" do

    before :each do
      ENV.fetch('QDISK_BEST', nil).should be_nil
    end

    let :default do
      [[:interface, 'usb'], :mounted?]
    end

    it "should return interface=usb,mounted if no .qdisk file" do
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_raise(Errno::ENOENT)
      derive_best.should eq([[:interface, 'usb'], :mounted?])
    end

    it "should return query from .qdisk if present" do
      file = StringIO.new("best=interface=ata,device=1:1")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      derive_best.should eq([[:interface, 'ata'], [:device, '1:1']])
    end

    it "should return default if no best line present" do
      file = StringIO.new("beset=interface=ata,device=1:1")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      derive_best.should eq(default)
    end

    it "should return default if no best line commented" do
      file = StringIO.new("#best=interface=ata,device=1:1")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      derive_best.should eq(default)
    end

    it "should return best line if other lines present" do
      file = StringIO.new("other=foo\nbest=interface=ata,device=1:2\n")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      derive_best.should eq([[:interface, 'ata'], [:device, '1:2']])
    end

    it "should return best line with comment/whitespace trimmed" do
      file = StringIO.new("best=interface=ata,device=2:2 # SATA disk 2\n")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      derive_best.should eq([[:interface, 'ata'], [:device, '2:2']])
    end

    it "should fail on bad query" do
      file = StringIO.new("best=badinterface=ata,device=1:1")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      expect { derive_best }.to raise_error(OptionParser::InvalidArgument)
    end
  end

  context "QDISK_BEST set" do

    context "with no .qdisk file" do

      before :each do
        expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_raise(Errno::ENOENT)
      end

      it "should return query from QDISK_BEST if present" do
        ENV['QDISK_BEST'] = 'interface=usb,device=8:1'
        derive_best.should eq([[:interface, 'usb'], [:device, '8:1']])
      end

      it "should default query if QDISK_BEST is empty" do
        ENV['QDISK_BEST'] = ''
        derive_best.should eq([[:interface, 'usb'], :mounted?])
      end

      it "should fail on bad query" do
        ENV['QDISK_BEST'] = 'unknowninterface=usb,device=8:1'
        expect { derive_best }.to raise_error(OptionParser::InvalidArgument)
      end

    end

    it "should return query from QDISK_BEST even if .qdisk present" do
      ENV['QDISK_BEST'] = 'interface=usb,device=8:2'
      file = StringIO.new("best=interface=ata,device=1:1")
      expect(File).to receive(:open).with(Pathname('/home/user/.qdisk')).and_yield(file)
      derive_best.should eq([[:interface, 'usb'], [:device, '8:2']])
    end

  end

end
