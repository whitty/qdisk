require 'qdisk/exceptions'
require 'yaml'

module QDisk

  class Info

    class Disk

      def initialize(raw)
        data, tables = raw.split(/^=+$/, 2)
        tables = nil if tables =~ /\A\s+\z/

        @raw = raw
        @tables = tables

        lines = data.split("\n")
        @object_name = lines.shift
        parse(lines)

        @device_name = @values['device-file'].value
        @partitions = nil
      end

      def complete(l)
        return if @partitions
        @partitions = l.select do |x|
          x.partition? and x.parent == @object_name
        end
        nil
      end

      attr_reader :object_name, :device_name, :partitions, :tables, :raw

      def partition?
        get('partition','part of') != nil
      end

      def to_s
        str = "#{@object_name} (#{@device_name})\n" << " @tables={"
        depth = 0
        str << "\n" if @tree.length
        @tree.each do |name, d|
          str << "  #{" " * depth} #{name} => #{d.value}\n"
        end
        str << "}"
        str
      end

      def method_missing(name, *args, &block)
        v = get(name)
        return v unless v.nil?
        super(name, *args, &block)
      end

      def respond_to_missing?(symbol, all)
        v = get(symbol)
        return true unless v.nil?
        super(symbol, all)
      end

      def get(name, subname = nil)
        source = subname.nil? ? @values : @tree
        c = get_candidates(name).find do |cand|
          source.member?(cand)
        end
        return nil if c.nil?
        entry = source[c] unless c.nil?

        if subname
          entry = entry.children.find_all do|ch|
            c = get_candidates(subname).find do |cand|
              ch.name == cand
            end
          end
        end
        unless entry.nil?
          if entry.is_a?(Array)
            if entry.length == 1
              entry.first.value
            else
              entry.map {|x| x.value}
            end
          else
            entry.value
          end
        end
      end

      private

      def get_candidates(name)
        name = name.to_s
        [name, name.gsub(/[-_]/,' '), name.gsub(/[ _]/,'-')]
      end

      Data = Struct.new(:name, :value, :children)

      def self.predicate(predicate)
        [*predicate].each do |pred|
          name = pred.sub(/^(is)\s+/,'').gsub(/\s+/, '_') + '?'
          define_method(name.to_sym) do
            v = @values.fetch(pred, nil)
            v and v.value
          end
        end
      end

      @@predicates = [
                      'is mounted',
                      'removable',
                      'has media',
                      'is read only',
                     ]
      predicate @@predicates

      def parse(lines)
        rows = lines.map do |l|
          if l =~ /^( +)([^:]+):\s*(.*)/
            [($1.length / 2) - 1, $2, $3]
          else
            nil
          end
        end.select {|x| x}

        @values = {}
        @tree = {}
        parent = nil
        stack = []
        last = nil
        last_depth = 0

        # special pre-parsing (with insertion)
        rows.each_with_index do | v, i |
          depth, name, value = v

          if name == "has media"
            value, rest = value.split(/\s/, 2)
            rows[i][2] = value
            rows.insert(i + 1, [depth + 1, "since", rest]) if rest
          end

        end

        rows.each do |depth, name, value|
          if @@predicates.member?(name)
            value = value == '1'
          end
          if depth > last_depth
            stack.push(parent) unless parent.nil?
            parent = last
          elsif depth < last_depth
            parent = stack.pop()
          end

          d = Data.new(name, value, [])
          unless @values.member?(name)
            @values[name] = d
          end
          @tree[name] = d if depth == 0
          parent.children << d unless parent.nil?

          last_depth = depth
          last = d
        end
        rows
      end
    end

    class Partition < Disk
      def initialize(*args)
        super(*args)
        @parent = @values['part of'].value
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
      status, output = run(['udisks', '--dump'])
      if status.exited? and status.exitstatus == 0
        raw_entries = output.split(/^=+\nShowing information for\s+/)
      else
        raise CommandFailed.new('udisks --dump', output)
      end

      @entries = []
      @disks = []
      @partitions = []
      raw_entries.each do |x|
        if x.length != 0
          disk = Disk.new(x)
          if disk.partition?
            disk = Partition.new(x)
            @partitions << disk
          else
            @disks << disk
          end
          @entries << disk
        end
      end
      @entries.each {|x| x.complete(@entries) }
    end
  end

end
