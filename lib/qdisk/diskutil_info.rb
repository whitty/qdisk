require 'qdisk/exceptions'
require 'yaml'

module QDisk

  module DiskUtil

    class Info

      class Disk

        def initialize(name)
          @device_name = name
          @info = nil
          @partition = false
          @partitions = []
        end

        attr_reader :device_name, :interface, :partitions

        def self.predicate(predicate)
          [*predicate].each do |pred|
            name = pred.to_s + '?'
            define_method(name.to_sym) do
              v = self.instance_variable_get('@' + pred.to_s)
              v and v.value
            end
          end
        end

        @@predicates = [
                        :mounted,
                        :removable,
                        :has_media,
                        :read_only,
                        :partition,
                       ]
        predicate @@predicates

        @@aliases = {
          'device-file' => :device_name,
          'device_file' => :device_name,
        }

        def get(name, subname = nil)
          load_info unless @info
          sym = @@aliases.fetch(name, nil)
          if sym.nil?
            sym = name.to_s.to_sym
          end
          if [name, subname] == [:device_file, 'by-id']
            return []
          end
          if subname
            self.send(sym, subname)
          else
            self.send(sym)
          end
        end

        def load_info
          status, output = run(['diskutil', 'info', @device_name])

          if ! status.exited? or status.exitstatus != 0
            raise CommandFailed.new('diskutil info ' + @device_name, output)
          end
          output.each_line do |l|
            case l
            when /^   Mounted:\s+(.*)/
              @mounted = ($1 == 'Yes')
            when /^   Protocol:\s+(.*)/
              case $1
              when 'PCI'
                @interface = 'ata'
              when 'Disk Image'
                @interface = 'loop'
              when 'USB'
                @interface = 'usb'
              end
            when /^   Read-Only Media:\s+(.*)/
              unless partition?
                @read_only = ($1 == 'Yes')
              end
            when /^   Read-Only Volume:\s+(.*)/
              if partition?
                @read_only = ($1 == 'Yes')
              end
            when /^   Ejectable:\s+(.*)/
              @removable = ($1 == 'Yes')
            end
          end
          @info = true
        end

        def register(child)
          if child.is_a?(Disk)
            unless @partitions.member?(child)
              @partitions << child
            end
          end
        end

      end

      class Partition < Disk
        def initialize(parent, *args)
          super(*args)
          @partition = true
          @parent = parent
          @parent.register(self)
        end
        attr_reader :parent
      end

      def initialize
        load
      end

      def disk(name)
        @disks.find {|x| x.object_name == name || x.device_name == name}
      end

      def partition(name)
        @partitions.find {|x| x.object_name == name || x.device_name == name}
      end


      def query_disks(query, value = nil)
        query_(@disks, query, value)
      end

      def query_partitions(query, value = nil)
        query_(@partitions, query, value)
      end

      attr_reader :disks, :partitions

      private

      def query_(list, query, value = nil)
        case query
        when :removable?, :mounted?, :read_only?, :has_media?
          list.find_all {|x| x.respond_to?(query) and x.send(query) }
        when :interface, :device, :usage, :type, :uuid, :label
          list.find_all {|x| x.respond_to?(query) and x.send(query) == value }
        else
          raise ArgumentError.new("Unknown query #{query}")
        end
      end

      def load
        status, output = run(['diskutil', 'list'])

        @entries = []
        @disks = []
        @partitions = []

        if status.exited? and status.exitstatus == 0
          disk = nil
          output.each_line do |l|
            if l =~ /^\/dev\/disk/
              disk = Disk.new(l.strip)
              @disks << disk
            end
            unless disk == nil
              if l =~ /^   ([0-9]+):/
                pnum = $1
                if pnum != '0'
                  partition = disk.device_name + 's' + $1
                  @partitions << Partition.new(disk, partition)
                end
              end
            end
          end
        else
          raise CommandFailed.new('diskutil list', output)
        end

      end
    end

  end
end
