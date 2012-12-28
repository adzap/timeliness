require 'singleton'

module Timeliness
  module Helpers
    class MonthNamesResolver
      include Singleton

      class << self
        def month_names names
          instance.base_month_names = names
        end
      end

      # Additional month's names to check while parsing month using 'mmmm' token
      # Should be an array of arrays of 13 elements: a placeholder and 12 months' names
      # (as in DATE::MONTHNAMES)
      #
      attr_accessor :base_month_names

      def base_month_names
        @base_month_names || []
      end

      def resolve month, locale_agnostic
        return month.to_i if month.to_i > 0 || /0+/ =~ month
        unless i18n_loaded?
          month_names = method(:month_names)
          abbr_month_names = method(:abbr_month_names)
        end

        if !locale_agnostic
          month_names ||= method(:i18n_month_names)
          abbr_month_names ||= method(:i18n_abbr_month_names)
        else
          month_names ||= method(:locale_agnostic_month_names)
          abbr_month_names ||= method(:locale_agnostic_abbr_month_names)
        end

        month.length > 3 ? month_names[month.mb_chars.capitalize] : abbr_month_names[month.mb_chars.capitalize]
      end

      def month_names month
        Date::MONTHNAMES.index(month)
      end

      def abbr_month_names month
        Date::ABBR_MONTHNAMES.index(month)
      end

      def i18n_month_names month
        I18n.t('date.month_names').index(month)
      end

      def i18n_abbr_month_names month
        I18n.t('date.abbr_month_names').index(month)
      end

      def locale_agnostic_month_names month
        names = values_for_locales('date.month_names')

        names.map { |locale| locale.index(month) }.compact.first
      end

      def locale_agnostic_abbr_month_names month
        names = values_for_locales('date.abbr_month_names')

        names.map { |locale| locale.index(month) }.compact.first
      end

      private

      def i18n_loaded?
        defined?(I18n)
      end

      def values_for_locales key
        values = base_month_names.dup

        I18n.available_locales.each do |locale|
          I18n.with_locale(locale) do
            values << I18n.t(key)
          end
        end

        values
      end
    end
  end
end
