module Timeliness
  module Parser
    class MissingTimezoneSupport < StandardError; end

    class << self

      def parse(value, *args)
        return value unless value.is_a?(String)

        options = args.last.is_a?(Hash) ? args.pop : {}
        type = args.first

        time_array = _parse(value, type, options)
        return nil if time_array.nil?

        case type
        when :date
          time_array[3..7] = nil
        when :time
          time_array[0..2] = current_date(options)
        when nil
          dummy_date = current_date(options)
          time_array[0] ||= dummy_date[0]
          time_array[1] ||= dummy_date[1]
          time_array[2] ||= dummy_date[2]
        end
        make_time(time_array[0..6], options[:zone])
      end

      def make_time(time_array, zone=nil)
        return nil unless fast_date_valid_with_fallback(*time_array[0..2])

        zone ||= Timeliness.default_timezone
        case zone
        when :utc, :local
          time_with_datetime_fallback(zone, *time_array.compact)
        when :current
          Time.zone.local(*time_array)
        else
          Time.use_zone(zone) { Time.zone.local(*time_array) }
        end
      rescue ArgumentError, TypeError
        nil
      rescue NoMethodError
        raise MissingTimezoneSupport, "You need to load ActiveSupport to use timezones other than :utc and :local."
      end

      def _parse(string, type=nil, options={})
        if options[:strict] && type
          set = Formats.send("#{type}_format_set")
          set.match(string, options[:format])
        else
          values = nil
          Formats.format_set(type, string).find {|set| values = set.match(string, options[:format]) }
          values
        end
      rescue
        nil
      end

      private

      def current_date(options)
        now = if options[:now]
          options[:now]
        elsif options[:zone]
          case options[:zone]
          when :utc, :local
            Time.now.send("get#{options[:zone]}")
          when :current
            Time.current
          else
            Time.use_zone(options[:zone]) { Time.current }
          end
        else
          Timeliness.date_for_time_type
        end
        now.is_a?(Array) ? now[0..2] : [now.year, now.month, now.day]
      end

      # Taken from ActiveSupport and simplified
      def time_with_datetime_fallback(utc_or_local, year, month=1, day=1, hour=0, min=0, sec=0, usec=0)
       return nil if hour > 23 || min > 59 || sec > 59
        ::Time.send(utc_or_local, year, month, day, hour, min, sec, usec)
      rescue
        offset = utc_or_local == :local ? (::Time.local(2007).utc_offset.to_r/86400) : 0
        ::DateTime.civil(year, month, day, hour, min, sec, offset)
      end

      # Enforce strict date part validity which the Time class does not.
      # Only does full date check if month and day are possibly invalid.
      def fast_date_valid_with_fallback(year, month, day)
        month < 13 && (day < 29 || Date.valid_civil?(year, month, day))
      end

    end

  end
end
