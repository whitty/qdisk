require 'qdisk/udisk_info'
require 'qdisk/diskutil_info'

module QDisk
  if RUBY_PLATFORM =~ /darwin/
    Info = DiskUtil::Info
  else
    Info = UDisk::Info
  end
end

