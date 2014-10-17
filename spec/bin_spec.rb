require 'spec_helper'
require 'support/command_run'

include QDisk

describe 'qdisk binary', :if => `which udisks` =~ /udisks$/ do
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
