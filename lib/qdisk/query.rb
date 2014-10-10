require 'qdisk/exceptions'
require 'set'

module QDisk
  extend self

  module Query
    extend self

  end

  def find_disks(info, options = {})
    queries = options.fetch(:query,[])
    return [] if options.fetch(:mandatory, false) and queries.length < 1

    candidates = info.disks.to_set

    queries.each do | query |
      case [*query].first
      when :mounted?
        # disks on own rights
        disk_candidates = info.query_disks(*query)
        # disks selected by matching partitions
        matching_partitions = info.query_partitions(*query)
        partition_based_disk_candidates = candidates.select do |disk|
          disk.partitions.any? {|part| matching_partitions.member?(part)}
        end
        candidates = disk_candidates.to_set.union(partition_based_disk_candidates.to_set)
      else
        candidates = candidates & info.query_disks(*query)
      end
    end

    candidates
  end

  def find_partitions(info, options = {})
    queries = options.fetch(:query,[])
    return [] if options.fetch(:mandatory, false) and queries.length < 1

    candidates = info.partitions.to_set

    queries.each do | query |
      case [*query].first
      when :interface, :removable?
        # partitions on own rights
        partition_candidates = info.query_partitions(*query)
        # partitions selected by parent disks
        matching_disks = info.query_disks(*query).map {|x| x.object_name }
        disk_based_partition_candidates = candidates.select do |part|
          matching_disks.member?(part.parent)
        end
        candidates = partition_candidates.to_set.union(disk_based_partition_candidates.to_set)
      else
        candidates = candidates & info.query_partitions(*query)
      end
    end

    candidates
  end

  def mandatory_target_query(options)
    info = QDisk::Info.new
    candidates = find_disks(info, options.merge(:mandatory => true))
    if candidates.length == 0
      raise NotFound.new
    end

    if options.fetch(:only, false)
      if candidates.length != 1
        raise NotUnique.new(candidates)
      end
    end

    if options.fetch(:last, false)
      candidates = [candidates.last]
    end
    candidates
  end

end
