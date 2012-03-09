require 'active_model/validations/numericality'

module Paperclip
  module Validators
    class AttachmentSizeValidator < ActiveModel::Validations::NumericalityValidator
      AVAILABLE_CHECKS = [:less_than, :less_than_or_equal_to, :greater_than, :greater_than_or_equal_to]

      def initialize(options)
        extract_options(options)
        super
      end

      def validate_each(record, attr_name, value)
        options.slice(*AVAILABLE_CHECKS).each do |option, option_value|
          option_value = option_value.call(record) if option_value.is_a?(Proc)
          # option_value = record.send(option_value) if option_value.is_a?(Symbol)
          option_value = extract_option_value(option, option_value)

          unless value.send(CHECKS[option], option_value)
            error_message_key = options[:in] ? :in_between : option
            record.errors.add(attr_name, error_message_key, filtered_options(value).merge(
              :min => min_value_in_human_size(record),
              :max => max_value_in_human_size(record),
              :count => human_size(option_value)
            ))
          end
        end
      end

      private

      def extract_options(options)
        if range = options[:in]
          if !options[:in].respond_to?(:call)
            options[:less_than_or_equal_to] = range.max
            options[:greater_than_or_equal_to] = range.min
          else
            options[:less_than_or_equal_to] = range
            options[:greater_than_or_equal_to] = range
          end
        end
      end

      def extract_option_value(option, option_value)
        if option_value.is_a?(Range)
          if [:less_than, :less_than_or_equal_to].include?(option)
            option_value.max
          else
            option_value.min
          end
        else
          option_value
        end
      end

      def human_size(size)
        storage_units_format = I18n.translate(:'number.human.storage_units.format', :locale => options[:locale], :raise => true)
        unit = I18n.translate(:'number.human.storage_units.units.byte', :locale => options[:locale], :count => size.to_i, :raise => true)
        storage_units_format.gsub(/%n/, size.to_i.to_s).gsub(/%u/, unit).html_safe
      end

      def min_value_in_human_size(record)
        value = options[:greater_than_or_equal_to] || options[:greater_than]
        value = value.call(record).min if value.respond_to?(:call)
        human_size(value)
      end

      def max_value_in_human_size(record)
        value = options[:less_than_or_equal_to] || options[:less_than]
        value = value.call(record).min if value.respond_to?(:call)
        human_size(value)
      end
    end
  end
end
