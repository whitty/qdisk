require 'spec_helper'
require 'support/command_run'

include QDisk

describe 'qdisk binary' do
  include_context "command run"

  describe :wait do

    it "returns non-zero if wait times out", :slow => true do
      l, r = run('wait', '--timeout=1.0', '--query=device=zz:yy')
      l.should be_empty
      r.should_not eq(0)
    end

  end

end
