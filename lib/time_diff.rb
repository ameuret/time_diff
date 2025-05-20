require 'rubygems'
# require 'active_support/time'
require 'i18n'

class Time
  SECONDS_PER = {
    'year' => 365 * 86_400, # Leap years are accounted for in the days part
    'month' => 86_400 * 30,
    'week' => 86_400 * 7,
    'day' => 86_400,
    'hour' => 3600,
    'minute' => 60,
    'second' => 1
  }.freeze

  def self.diff(start_date, end_date, format_string='%y, %M, %w, %d and %h:%m:%s')
    I18n.available_locales = [:en]
    I18n.default_locale = :en
#I18n.load_path += Dir.glob("lib/*.yml")
    start_time = start_date.to_time if start_date.respond_to?(:to_time)
    end_time = end_date.to_time if end_date.respond_to?(:to_time)
    distance_in_seconds = ((end_time - start_time).abs).round
    # byebg

    components = get_time_diff_components(%w(year month week day hour minute second), distance_in_seconds)
    time_diff_components = {:year => components[0], :month => components[1], :week => components[2], :day => components[3], :hour => components[4], :minute => components[5], :second => components[6]}

    formatted_intervals = get_formatted_intervals(format_string)
    components = get_time_diff_components(formatted_intervals, distance_in_seconds)
    formatted_components = create_formatted_component_hash(components, formatted_intervals)
    format_string = remove_format_string_for_zero_components(formatted_components, format_string)
    time_diff_components[:diff] = format_date_time(formatted_components, format_string) unless format_string.nil?
    return time_diff_components
  end

  def self.get_formatted_intervals(format_string)
    intervals = []
    [{'year' => '%y'}, {'month' => '%M'}, {'week' => '%w'}, {'day' => '%d'}].each do |component|
      key = component.keys.first
      value = component.values.first
      intervals << key if format_string.include?(value)
    end
    intervals << 'hour' if format_string.include?('%h') || format_string.include?('%H')
    intervals << 'minute' if format_string.include?('%m') || format_string.include?('%N')
    intervals << 'second' if format_string.include?('%s') || format_string.include?('%S')
    intervals
  end

  def self.create_formatted_component_hash(components, formatted_intervals)
    formatted_components = {}
    index = 0
    components.each do |component|
      formatted_components[:"#{formatted_intervals[index]}"] = component
      index = index + 1
    end
    formatted_components
  end

  def self.get_time_diff_components(intervals, distance_in_seconds)
    components = []
    intervals.each do |interval|
      component = (distance_in_seconds / SECONDS_PER[interval]).floor
      distance_in_seconds -= component * SECONDS_PER[interval]
      components << component
    end
    components
  end

  def Time.format_date_time(time_diff_components, format_string)
    [{:year => '%y'}, {:month => '%M'}, {:week => '%w'}, {:day => '%d'}, {:hour => '%H'}, {:minute => '%N'}, {:second => '%S'}].each do |component|
      key = component.keys.first
      value = component.values.first
      format_string.gsub!(value, "#{time_diff_components[key]} #{pluralize(key.to_s, time_diff_components[key])}") if time_diff_components[key] 
    end
    [{:hour => '%h'},{:minute => '%m'},{:second => '%s'}].each do |component|
      key = component.keys.first
      value = component.values.first
      format_string.gsub!(value, format_digit(time_diff_components[key]).to_s) if time_diff_components[key]
    end
    format_string
  end

  def Time.pluralize(word, count)
    return count != 1 ? I18n.t("#{word}s", :default => "#{word}s") : I18n.t(word, :default =>  word)
  end

  def Time.remove_format_string_for_zero_components(time_diff_components, format_string)
    [{minute: '%N'}, {hour: '%H'}, {:year => '%y'}, {:month => '%M'}, {:week => '%w'}].each do |component|
      key = component.keys.first
      value = component.values.first
      format_string.gsub!(/#{value},?\s?/,'') if time_diff_components[key].nil? || time_diff_components[key].zero?
    end
    if time_diff_components[:day].nil? || time_diff_components[:day].zero?
      (format_string.slice(0..1) == '%d')? format_string.gsub!('%d ','') : format_string.gsub!(', %d','')
    end
    format_string.slice!(0..3) if format_string.slice(0..3) == 'and ' 
    format_string
  end

  def Time.format_digit(number)
    return '%02d' % number
  end
end
