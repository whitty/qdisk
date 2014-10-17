require 'spec_helper'
require 'support/command_run'

include QDisk

def has_udisk?
  which = `which udisks`
  p [which, ENV['TRAVIS']]
  which =~ /udisks$/ and ENV['TRAVIS'] != 'true'
end

describe 'qdisk binary', :if => has_udisk? do
  include_context "command run"

  describe :wait do

    it "returns non-zero if wait times out", :slow => true do
      l, r = run('wait', '--timeout=1.0', '--query=device=zz:yy')
      l.should be_empty
      r.should_not eq(0)
    end

  end

  describe :unmount do

    it "returns non-zero if device does not exist" do
      l, r = run('unmount', '--query=device=zz:yy')
      l.first.should match(/No .* device found/)
      r.should_not eq(0)
    end

  end

end
