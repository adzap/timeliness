module Timeliness
  class FormatSet
    include Helpers

    attr_reader :formats, :regexp

    class << self

      def compile(formats)
        set = new(formats)
        set.compile!
        set
      end

      def compile_format(string_format)
        format = string_format.dup
        format.gsub!(/([\.\\])/, '\\\\\1') # escapes dots and backslashes
        found_tokens, token_order, value_token_count = [], [], 0

        # Substitute tokens with numbered placeholder
        Formats.sorted_token_keys.each do |token|
          regexp_str, arg_key = *Formats.format_tokens[token]
          if format.gsub!(/#{token}/, "%<#{found_tokens.size}>")
            if arg_key
              regexp_str = "(#{regexp_str})"
              value_token_count += 1
            end
            found_tokens << [regexp_str, arg_key]
          end
        end

        # Replace placeholders with token regexps
        format.scan(/%<(\d)>/).each {|token_index|
          token_index = token_index.first
          regexp_str, arg_key = found_tokens[token_index.to_i]
          format.gsub!("%<#{token_index}>", regexp_str)
          token_order << arg_key
        }

        define_format_method(string_format, token_order.compact)
        return format, value_token_count
      rescue
        raise "The following format regular expression failed to compile: #{format}\n from format #{string_format}."
      end

      # Compiles a format method which maps the regexp capture groups to method
      # arguments based on order captured. A time array is built using the argument
      # values placed in the position defined by the component.
      #
      def define_format_method(name, components)
        values = [nil] * 7
        components.each do |component|
          position, code = *Formats.format_components[component]
          values[position] = code || "#{component}.to_i" if position
        end
        class_eval <<-DEF
          define_method(:"format_#{name}") do |#{components.join(',')}|
            [#{values.map {|i| i || 'nil' }.join(',')}]
          end
        DEF
      end

    end

    def initialize(formats)
      @formats = formats
    end

    # Compiles the formats into one big regexp. Stores the index of where
    # each format's capture values begin in the match data. Each individual
    # format regpexp is also stored for use with the parse :format option.
    #
    def compile!
      regexp_string   = ''
      @format_regexps = {}
      @match_indexes  = {}
      @formats.inject(0) { |index, format|
        format_regexp, token_count = self.class.compile_format(format)
        @format_regexps[format] = Regexp.new("^(#{format_regexp})$")
        @match_indexes[index]   = format
        regexp_string = "#{regexp_string}(#{format_regexp})|"
        index + token_count + 1 # add one for wrapper capture
      }
      @regexp = Regexp.new("^(?:#{regexp_string.chop})$")
    end

    def match(string, format=nil)
      match_regexp = format ? @format_regexps[format] : @regexp
      if match_data = match_regexp.match(string)
        index    = match_data.captures.index(string)
        start    = index + 1
        values   = match_data.captures[start..(start+7)].compact
        format ||= @match_indexes[index]
        send(:"format_#{format}", *values)
      end
    end

  end
end
