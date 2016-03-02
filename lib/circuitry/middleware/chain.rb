require 'circuitry/middleware/entry'

module Circuitry
  module Middleware
    class Chain
      include Enumerable

      def initialize
        yield self if block_given?
      end

      def each(&block)
        entries.each(&block)
      end

      def entries
        @entries ||= []
      end

      def add(klass, *args)
        remove(klass) if exists?(klass)
        entries << Entry.new(klass, *args)
      end

      def remove(klass)
        entries.delete_if { |entry| entry.klass == klass }
      end

      def prepend(klass, *args)
        remove(klass) if exists?(klass)
        entries.unshift(Entry.new(klass, *args))
      end

      def insert_before(old_klass, new_klass, *args)
        new_entry = build_or_replace_entry(new_klass, *args)
        i = entries.index { |entry| entry.klass == old_klass } || 0
        entries.insert(i, new_entry)
      end

      def insert_after(old_klass, new_klass, *args)
        new_entry = build_or_replace_entry(new_klass, *args)
        i = entries.index { |entry| entry.klass == old_klass } || entries.size - 1
        entries.insert(i + 1, new_entry)
      end

      def exists?(klass)
        any? { |entry| entry.klass == klass }
      end

      def build
        map(&:build)
      end

      def clear
        entries.clear
      end

      def invoke(*args)
        chain = build.dup

        traverse_chain = lambda do
          if chain.empty?
            yield
          else
            chain.shift.call(*args, &traverse_chain)
          end
        end

        traverse_chain.call
      end

      private

      def build_or_replace_entry(klass, *args)
        i = entries.index { |entry| entry.klass == klass }
        entry = i.nil? ? Entry.new(klass, *args) : entries.delete_at(i)

        if entry.args == args
          entry
        else
          Entry.new(klass, *args)
        end
      end
    end
  end
end
