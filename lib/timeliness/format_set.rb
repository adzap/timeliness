module Timeliness
  class FormatSet
    include Helpers

    attr_reader :formats, :regexp

    def initialize(formats)
      @formats = formats
    end

    def compile!
      regexp_string = ''
      @match_indexes = {}
      @formats.inject(0) { |match_index, format|
        token_count, format_regexp = self.class.compile_format(format)
        @match_indexes[match_index] = format
        regexp_string = "#{regexp_string}(#{format_regexp})|"
        match_index + token_count + 1 # add one for wrapper capture
      }
      @regexp = Regexp.new("^(#{regexp_string.chop})$")
    end

    def format_for_index(index)
      @match_indexes[index]
    end

    def self.compile(formats)
      set = new(formats)
      set.compile!
      set
    end

    def self.compile_format(string_format)
      format = string_format.dup
      format.gsub!(/([\.\\])/, '\\\\\1') # escapes dots and backslashes
      found_tokens, token_order, value_token_count = [], [], 0

      # Substitute tokens with numbered placeholder
      Parser.sorted_token_keys.each do |token|
        regexp_str, arg_key = *Parser.format_tokens[token]
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
        token = found_tokens[token_index.to_i]
        format.gsub!("%<#{token_index}>", token[0])
        token_order << token[1]
      }

      define_format_method(token_order.compact, string_format)
      return value_token_count, format
    rescue
      raise "The following format regular expression failed to compile: #{format}\n from format #{string_format}."
    end

    # Compiles a format method which maps the regexp capture groups to method
    # arguments based on order captured. A time array is built using the argument
    # values placed in the position defined by the component.
    #
    def self.define_format_method(components, name)
      values = [nil] * 7
      components.each do |component|
        position, code = *Parser.format_components[component]
        values[position] = code || "#{component}.to_i" if position
      end
      class_eval <<-DEF
        define_method(:"format_#{name}") do |#{components.join(',')}|
          [#{values.map {|i| i || 'nil' }.join(',')}]
        end
      DEF
    end

  end
end
