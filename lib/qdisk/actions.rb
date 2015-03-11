require 'qdisk/exceptions'
require 'set'
require 'fileutils'
require 'pathname'
require 'timeout'

module QDisk
  extend self

  def unmount(options)
    options[:only] = true unless options.fetch(:multi, false)
    candidates = mandatory_target_query(options)
    candidates.each do | disk |
      disk.partitions.each do |part|
        if part.mounted?
          QDisk.unmount_partition(part, options)
        end
      end
      if disk.mounted?
        QDisk.unmount_partition(disk, options)
      end
      if options.fetch(:detach, false)
        QDisk.detach_disk(disk, options)
      end
    end
  end

  def cp(args, options)
    raise InvalidParameter.new('--multi', 'cp') if options.fetch(:multi, false)
    if args.length < 1
      raise MissingRequiredArgument, 'copy source'
    end
    if args.length < 2
      raise MissingRequiredArgument, 'destination'
    end
    destination = args.pop

    options[:only] = true
    candidates = mandatory_target_query(options)
    disk = candidates.first
    puts "disk => #{disk.device_name}" if options[:verbose]
    part = disk.partitions.find do |p|
      p.mounted?
    end
    if part.nil?
      part = disk if disk.mounted?
    end
    raise NotFound, 'partition' if part.nil?
    puts "partition => #{part.device_name}" if options[:verbose]
    path = part.get('mount paths')
    raise NotFound, 'partition' unless path
    args = args.first if args.length == 1
    FileUtils.cp(args, Pathname(path) + destination, :verbose => options[:verbose], :noop => options[:no_act])
  end

  def run(args, options = {})
    p args if $DEBUG
    puts args.join(' ') if options.fetch(:verbose, false)
    return [nil, nil] if options.fetch(:no_act, false)
    IO.popen(args) do |f|
      pid = f.pid
      _, status = Process.wait2(pid)
      return [status, f.read]
    end
  end

  def unmount_partition(partition, options = {})
    cmd = %w{udisks --unmount} << partition.device_name
    status, output = QDisk.run(cmd, :verbose => options[:verbose], :no_act => options[:no_act])
    if status.nil? and output.nil?
      true # no_act
    elsif status.exited? and status.exitstatus == 0
      true
    elsif output =~ /Unmount failed: Device is not mounted/
      true
    else
      raise UnmountFailed.new(partition, output)
    end
  end

  def mount_partition(partition, options = {})
    cmd = %w{udisks --mount} << partition.device_name
    status, output = QDisk.run(cmd, :verbose => options[:verbose], :no_act => options[:no_act])
    if status.nil? and output.nil?
      true # no_act
    elsif status.exited? and status.exitstatus == 0
      true
    elsif output =~ /Mount failed: .* is mounted$/
      true
    else
      raise MountFailed.new(partition, output)
    end
  end

  def detach_disk(disk, options = {})
    cmd = %w{udisks --detach} << disk.device_name
    status, output = QDisk.run(cmd, :verbose => options[:verbose], :no_act => options[:no_act])
    if status.nil? and output.nil?
      true # no_act
    elsif status.exited? and status.exitstatus == 0
      raise DetachFailed.new(disk, output) if (output and output =~ /^Detach failed: /)
      true
    else
      raise DetachFailed.new(disk, output)
    end
  end

  def query(args, options)
    raise InvalidParameter.new('--multi', 'timeout') unless options.fetch(:timeout, nil).nil?
    query_(args, options, false)
  end

  def wait(args, options)
    query_(args, options, true)
  end

  private
  def query_(args, options, wait)
    if options[:query].nil? or options[:query].empty?
      raise MissingRequiredArgument, '--query'
    end
    work = lambda do
      found = nil
      mcount = 0 # mount count

      while true
        info = QDisk::Info.new
        found = QDisk.find(info, {:query => options[:query] })
        break if !wait
        break if found and !found.empty?

        # Not the best place for this
        if options[:mount] and options[:query].member?(:mounted?)
          # replay query to see if there are unmounted filesystems
          # that could satisfy the query
          present = options[:query].select{|x| x != :mounted?}
          present << [:usage, 'filesystem']
          p present if $DEBUG
          found = QDisk.find(info, {:query => present })
          # If there is exactly one candidate - note it and attempt to mount it
          # if we remain unsatisfied
          if found.length == 1 # one candidate
            if mcount > 1 # seen on two iterations
              if (mcount % 5) == 0 # each second
                puts "Attempt to mount #{found.first.device_name}"
                QDisk.mount_partition(found.first, options)
              end
            end
            mcount +=1
          else
            mcount = 0 # not seen or confusing
          end
        end
        sleep(0.2)
      end
      found
    end

    if options[:timeout]
      Timeout.timeout(options[:timeout]) {|x| work.call}
    else
      work.call
    end
  rescue Timeout::Error
    return false
  end

end
