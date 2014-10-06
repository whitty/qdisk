require 'spec_helper'

include QDisk

describe :parse_options do

  it 'should support --help' do
    begin
      orig = $stdout
      $stdout = StringIO.new
      lambda { parse_options(["--help"]) }.should exit_with_code(0)
     ensure
      $stdout = orig
    end
  end

  it 'should support --verbose' do
    options,_ = parse_options(["--verbose", 'unmount'])
    options.should include(:verbose)
  end

end
