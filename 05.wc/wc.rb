#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

class WcCommand
  OPTION_KEYS = %i[lines words bytes].freeze

  def initialize(files = [], options = [])
    @options = (options.length.positive? ? options : { lines: true, words: true, bytes: true })
    @inputs =
      if files.empty?
        stdin_input = $stdin.read
        [{ content: stdin_input, type: :stdin, name: nil }]
      else
        files.map do |file|
          input = { content: nil, type: nil, name: file }
          if FileTest.directory?(file)
            input[:type] = :dir
          elsif Pathname.new(file).exist?
            input[:type] = :file
            input[:content] = File.read(file)
          end
          input
        end
      end
  end

  def display_result
    output_lines = create_output_lines
    puts output_lines
  end

  def create_output_lines
    output_info_hashes = create_output_info
    output_info_hashes << calc_total(output_info_hashes) if output_info_hashes.length >= 2
    display_width = calc_display_width(output_info_hashes)
    format_output_info_hashes_to_output_lines(output_info_hashes, display_width)
  end

  def create_output_info
    @inputs.map do |input|
      output_info_hash = { lines: nil, words: nil, bytes: nil, file: nil, message: nil }
      output_info_hash[:message] = "wc: #{input[:name]}: Is a directory" if input[:type] == :dir

      if input[:type].nil?
        output_info_hash[:message] = "wc: #{input[:name]}: No such file or directory"
        next output_info_hash
      end

      output_info_hash[:lines] = count_lines_num(input[:content]) if @options[:lines]
      output_info_hash[:words] = count_words_num(input[:content]) if @options[:words]
      output_info_hash[:bytes] = count_bytesize(input[:content]) if @options[:bytes]
      output_info_hash[:file] = input[:name]
      output_info_hash
    end
  end

  def count_lines_num(content)
    content.nil? ? 0 : content.lines.length
  end

  def count_words_num(content)
    content.nil? ? 0 : content.split(/\s+/).length
  end

  def count_bytesize(content)
    content.nil? ? 0 : content.bytesize
  end

  def calc_display_width(output_info_hashes)
    OPTION_KEYS.map do |key|
      next unless @options[key]

      output_info_hashes
        .select { |output_info_hash| output_info_hash[key] } # 値のある要素だけを選択
        .map { |output_info_hash| count_digits(output_info_hash[key]) }
        .max
    end.compact.max
  end

  def calc_total(output_info_hashes)
    total_hash = { file: 'total' }
    OPTION_KEYS.each do |key|
      next unless @options[key]

      total_hash[key] = output_info_hashes
                        .select { |output_info_hash| output_info_hash[key] } # 値のある要素だけを選択
                        .sum { |output_info_hash| output_info_hash[key] }
    end
    total_hash
  end

  def format_output_info_hashes_to_output_lines(output_info_hashes, display_width)
    output_lines = []
    output_info_hashes.each do |output_info_hash|
      if output_info_hash[:message]
        output_lines << output_info_hash[:message]
        next unless output_info_hash[:type] == :dir
      end

      output_line = OPTION_KEYS.map do |key|
        next unless output_info_hash[key]

        format_number(output_info_hash[key], display_width)
      end.compact.join(' ')

      output_line += " #{output_info_hash[:file]}"
      output_lines << output_line
    end
    output_lines
  end

  def count_digits(num)
    num.abs.to_s.length
  end

  def format_number(num, digits)
    format("%#{digits}d", num)
  end
end

options = {}
opt = OptionParser.new
opt.banner = 'Usage: ls.rb [options]'
opt.on('-l', '--lines', 'print the newline counts') { options[:lines] = true }
opt.on('-w', '--words', 'print the word counts') { options[:words] = true }
opt.on('-c', '--bytes', 'print the byte counts') { options[:bytes] = true }
opt.parse!(ARGV)
files = ARGV

wc = WcCommand.new(files, options)
wc.display_result
