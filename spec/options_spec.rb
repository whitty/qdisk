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

end
