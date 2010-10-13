module Timeliness
  # A date and time parsing library which allows you to add custom formats using
  # simple predefined tokens. This makes it much easier to catalogue and customize
  # the formats rather than dealing directly with regular expressions.
  #
  # Formats can be added or removed to customize the set of valid date or time
  # string values.
  #
  module Parser

    # Format tokens:
    #       y = year
    #       m = month
    #       d = day
    #       h = hour
    #       n = minute
    #       s = second
    #       u = micro-seconds
    #    ampm = meridian (am or pm) with or without dots (e.g. am, a.m, or a.m.)
    #       _ = optional space
    #      tz = Timezone abbreviation (e.g. UTC, GMT, PST, EST)
    #      zo = Timezone offset (e.g. +10:00, -08:00, +1000)
    #
    # All other characters are considered literal. You can embed regexp in the
    # format but no guarantees that it will remain intact. If you don't use capture
    # groups, dots or backslashes in the regexp, it may well work as expected.
    # For special characters, use POSIX character classes for safety.
    #
    # Repeating tokens:
    #       x = 1 or 2 digits for unit (e.g. 'h' means an hour can be '9' or '09')
    #      xx = 2 digits exactly for unit (e.g. 'hh' means an hour can only be '09')
    #
    # Special Cases:
    #      yy = 2 or 4 digit year
    #    yyyy = exactly 4 digit year
    #     mmm = month long name (e.g. 'Jul' or 'July')
    #     ddd = Day name of 3 to 9 letters (e.g. Wed or Wednesday)
    #       u = microseconds matches 1 to 6 digits

    @time_formats = [
      'hh:nn:ss',
      'hh-nn-ss',
      'h:nn',
      'h.nn',
      'h nn',
      'h-nn',
      'h:nn_ampm',
      'h.nn_ampm',
      'h nn_ampm',
      'h-nn_ampm',
      'h_ampm'
    ]

    @date_formats = [
      'yyyy-mm-dd',
      'yyyy/mm/dd',
      'yyyy.mm.dd',
      'm/d/yy',
      'd/m/yy',
      'm\d\yy',
      'd\m\yy',
      'd-m-yy',
      'dd-mm-yyyy',
      'd.m.yy',
      'd mmm yy'
    ]

    @datetime_formats = [
      'yyyy-mm-dd hh:nn:ss.u',
      'yyyy-mm-dd hh:nn:ss',
      'yyyy-mm-dd h:nn',
      'yyyy-mm-dd h:nn_ampm',
      'm/d/yy h:nn:ss',
      'm/d/yy h:nn_ampm',
      'm/d/yy h:nn',
      'd/m/yy hh:nn:ss',
      'd/m/yy h:nn_ampm',
      'd/m/yy h:nn',
      'dd-mm-yyyy hh:nn:ss',
      'dd-mm-yyyy h:nn_ampm',
      'dd-mm-yyyy h:nn',
      'ddd, dd mmm yyyy hh:nn:ss tz', # RFC 822
      'ddd, dd mmm yyyy hh:nn:ss zo', # RFC 822
      'ddd mmm d hh:nn:ss zo yyyy', # Ruby time string
      'yyyy-mm-ddThh:nn:ssZ', # ISO 8601 without zone offset
      'yyyy-mm-ddThh:nn:sszo' # ISO 8601 with zone offset
    ]

    # All tokens available for format construction. The token array is made of
    # regexp and key for format component mapping, if any.
    #
    @format_tokens = {
      'ddd'  => [ '\w{3,9}' ],
      'dd'   => [ '\d{2}',   :day ],
      'd'    => [ '\d{1,2}', :day ],
      'mmm'  => [ '\w{3,9}', :month ],
      'mm'   => [ '\d{2}',   :month ],
      'm'    => [ '\d{1,2}', :month ],
      'yyyy' => [ '\d{4}',   :year ],
      'yy'   => [ '\d{4}|\d{2}', :year ],
      'hh'   => [ '\d{2}',   :hour ],
      'h'    => [ '\d{1,2}', :hour ],
      'nn'   => [ '\d{2}',   :min ],
      'n'    => [ '\d{1,2}', :min ],
      'ss'   => [ '\d{2}',   :sec ],
      's'    => [ '\d{1,2}', :sec ],
      'u'    => [ '\d{1,6}', :usec ],
      'ampm' => [ '[aApP]\.?[mM]\.?', :meridian ],
      'zo'   => [ '[+-]\d{2}:?\d{2}', :offset ],
      'tz'   => [ '[A-Z]{1,4}' ],
      '_'    => [ '\s?' ]
    }

    # Component argument values will be passed to the format method if matched in
    # the time string. The key should match the key defined in the format tokens.
    #
    # The array consists of the position the value should be inserted in
    # the time array, and the code to place in the time array.
    #
    # If the position is nil, then the value won't be put in the time array. If the
    # code is nil, then just the raw value is used.
    #
    @format_components = {
      :year     => [ 0, 'unambiguous_year(year)'],
      :month    => [ 1, 'month_index(month)'],
      :day      => [ 2 ],
      :hour     => [ 3, 'full_hour(hour, meridian ||= nil)'],
      :min      => [ 4 ],
      :sec      => [ 5 ],
      :usec     => [ 6, 'microseconds(usec)'],
      :offset   => [ 7, 'offset_in_seconds(offset)'],
      :meridian => [ nil ]
    }

    US_FORMAT_REGEXP = /\Am{1,2}[^m]/

    class << self
      attr_accessor :time_formats, :date_formats, :datetime_formats, :format_tokens, :format_components

      def parse(value, type=nil, options={})
        return value unless value.is_a?(String)

        time_array = _parse(value, type, options)
        return nil if time_array.nil?

        if type == :date
          time_array[3..7] = nil
        elsif type == :time
          time_array[0..2] = current_date(options)
        elsif type.nil?
          dummy_date = current_date(options)
          time_array[0] ||= dummy_date[0]
          time_array[1] ||= dummy_date[1]
          time_array[2] ||= dummy_date[2]
        end
        make_time(time_array[0..6], options[:zone])
      end

      def make_time(time_array, zone=nil)
        return nil unless fast_date_valid_with_fallback(*time_array[0..2])

        case zone
        when nil, :utc, :local
          time_with_datetime_fallback(zone || Timeliness.default_timezone, *time_array.compact)
        when :current
          Time.zone.local(*time_array)
        else
          Time.use_zone(zone) { Time.zone.local(*time_array) }
        end
      rescue ArgumentError, TypeError
        nil
      end

      def _parse(string, type=nil, options={})
        if options[:strict]
          set = send("#{type}_format_set")
          set.match(string, options[:format])
        else
          values = nil
          format_set(type, string).find {|set| values = set.match(string, options[:format]) }
          values
        end
      rescue
        nil
      end

      # Delete formats of specified type. Error raised if format not found.
      #
      def remove_formats(type, *remove_formats)
        remove_formats.each do |format|
          unless send("#{type}_formats").delete(format)
            raise "Format #{format} not found in #{type} formats"
          end
        end
        compile_formats
      end

      # Adds new formats. Must specify format type and can specify a :before
      # option to nominate which format the new formats should be inserted in
      # front on to take higher precedence.
      #
      # Error is raised if format already exists or if :before format is not found.
      #
      def add_formats(type, *add_formats)
        formats = send("#{type}_formats")
        options = add_formats.last.is_a?(Hash) ? add_formats.pop : {}
        before  = options[:before]
        raise "Format for :before option #{format} was not found." if before && !formats.include?(before)

        add_formats.each do |format|
          raise "Format #{format} is already included in #{type} formats" if formats.include?(format)

          index = before ? formats.index(before) : -1
          formats.insert(index, format)
        end
        compile_formats
      end

      # Removes US date formats so that ambigious dates are parsed as European format
      #
      def use_euro_formats
        @date_format_set     = FormatSet.compile(date_formats.select { |format| US_FORMAT_REGEXP !~ format })
        @datetime_format_set = FormatSet.compile(datetime_formats.select { |format| US_FORMAT_REGEXP !~ format })
      end

      # Restores default to parse ambiguous dates as US format
      #
      def use_us_formats
        @date_format_set     = FormatSet.compile(date_formats)
        @datetime_format_set = FormatSet.compile(datetime_formats)
      end

      def compile_formats
        @sorted_token_keys   = nil
        @time_format_set     = FormatSet.compile(time_formats)
        @date_format_set     = FormatSet.compile(date_formats)
        @datetime_format_set = FormatSet.compile(datetime_formats)
      end

      def sorted_token_keys
        @sorted_token_keys ||= format_tokens.keys.sort {|a,b| a.size <=> b.size }.reverse
      end

    private

      def current_date(options)
        now = if options[:now]
          options[:now]
        elsif options[:zone]
          case options[:zone]
          when :utc, :local
            Time.now.send("get#{options[:zone] || Timeliness.default_timezone}")
          when :current
            Time.current
          else
            Time.use_zone(options[:zone]) { Time.current }
          end
        end
        now = Array(now).reverse[4..6] if now
        now ||= Timeliness.date_for_time_type
        now[0..2]
      end

      # Returns format for type and other possible matching format set based on type
      # and value length. Gives minor speed-up by checking string length.
      def format_set(type, string)
        case type
        when :date
          [ @date_format_set, @datetime_format_set ]
        when :time
          if string.length < 11
            [ @time_format_set ]
          else
            [ @datetime_format_set, @time_format_set ]
          end
        when :datetime
          if string.length < 11
            [ @date_format_set, @datetime_format_set ]
          else
            [ @datetime_format_set, @date_format_set ]
          end
        else
          if string.length < 11
            [ @date_format_set, @time_format_set, @datetime_format_set ]
          else
            [ @datetime_format_set, @date_format_set, @time_format_set ]
          end
        end
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

Timeliness::Parser.compile_formats
