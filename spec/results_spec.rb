require 'spec_helper'
require 'stringio'

include QDisk

describe QDisk::Query do

  let :io do
    StringIO.new
  end

  describe :print do

    it "emits nothing if results is nil" do
      QDisk.print(nil, {}, io)
      io.string.should be_empty
    end
    it "emits nothing if results is false" do
      QDisk.print(false, {}, io)
      io.string.should be_empty
    end
    it "emits nothing if results is empty" do
      QDisk.print([], {}, io)
      io.string.should be_empty
    end

  end

end
