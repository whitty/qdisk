require 'spec_helper'

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

  end

end
