require 'qdisk/exceptions'
require 'set'

module QDisk

  def find_disks(info, options = {})
    candidates = info.disks.to_set
    options.fetch(:query,[]).each do | query |
      case query
      when :mounted?
        candidates.select! do |d|
          if d.mounted?
            true
          else
            d.partitions.find {|p| p.mounted? }
          end
        end
      else
        candidates = candidates & info.query_disks(*query)
      end
    end
    candidates
  end

  def unmount(options)
    info = QDisk::Info.new
    candidates = find_disks(info, options)
    if candidates.length == 0
      raise NotFound.new
    end
    if options.fetch(:only, false)
      if candidates.length != 1
        raise NotUnique.new(candidates)
      end
    end


    candidates.each do | disk |
      disk.partitions.each do |part|
        if part.mounted?
          QDisk.unmount_partition(part, options)
        end
      end
      if options.fetch(:detach, false)
        QDisk.detach_disk(disk, options)
      end
    end
  end

  def run(args)
    p args if $DEBUG
    IO.popen(args) do |f|
      pid = f.pid
      _, status = Process.wait2(pid)
      [status, f.read]
    end
  end

  def unmount_partition(partition, options = {})
    cmd = %w{udisks --unmount} << partition.device_name
    if options.fetch(:no_act, false)
      puts cmd.join(' ')
      return true
    end
    status, output = QDisk.run(cmd)
    if status.exited? and status.exitstatus == 0
      true
    elsif output =~ /Unmount failed: Device is not mounted/
      true
    else
      raise UnmountFailed.new(partition, output)
    end
  end

  def detach_disk(disk, options = {})
    cmd = %w{udisks --detach} << disk.device_name
    if options.fetch(:no_act, false)
      puts cmd.join(' ')
      return true
    end
    status, output = QDisk.run(cmd)
    if status.exited? and status.exitstatus == 0
      true
    elsif output =~ /Unmount failed: Device is not mounted/
      true
    else
      raise DetachFailed.new(disk, output)
    end
  end
end
