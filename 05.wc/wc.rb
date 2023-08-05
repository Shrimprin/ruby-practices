#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

class WcCommand
  FILE_INFO_KEYS = %i[lines words bytes].freeze

  def initialize(files = [], options = [])
    @options = (options.length.positive? ? options : { lines: true, words: true, bytes: true })
    if files.empty?
      @stdin = process_stdin
    else
      @files = files
    end
  end

  def process_stdin
    $stdin.read
  end

  def display_result
    output_lines = create_output_lines
    puts output_lines
  end

  def create_output_lines
    if @stdin
      stdin_info_array = gather_stdin_info
      display_width = calc_stdin_display_width(stdin_info_array)
      format_stdin_info_array_to_output_line(stdin_info_array, display_width)
    elsif @files
      file_info_hashes = gather_file_info
      file_info_hashes << calc_total(file_info_hashes) if file_info_hashes.length >= 2
      display_width = calc_file_display_width(file_info_hashes)
      format_file_info_hashes_to_output_lines(file_info_hashes, display_width)
    end
  end

  def gather_stdin_info
    stdin_info_array = []
    stdin_info_array << count_stdin_lines_num if @options[:lines]
    stdin_info_array << count_stdin_words_num if @options[:words]
    stdin_info_array << count_stdin_bytesize if @options[:bytes]
    stdin_info_array
  end

  def count_stdin_lines_num
    @stdin.lines.length
  end

  def count_stdin_words_num
    @stdin.split(/\s+/).length
  end

  def count_stdin_bytesize
    @stdin.bytesize
  end

  def gather_file_info
    @files.map do |file|
      # lines: 行数, words: 単語数, bytes: ファイルサイズ, file: ファイル名, message: ディレクトリの場合、指定ファイルが存在しない場合のメッセージ
      file_info_hash = { lines: nil, words: nil, bytes: nil, file: nil, message: nil }
      file_info_hash[:message] = "wc: #{file}: Is a directory" if FileTest.directory?(file)

      if !Pathname.new(file).exist?
        file_info_hash[:message] = "wc: #{file}: No such file or directory"
        next file_info_hash
      end

      file_info_hash[:lines] = count_file_lines_num(file) if @options[:lines]
      file_info_hash[:words] = count_file_words_num(file) if @options[:words]
      file_info_hash[:bytes] = count_file_bytesize(file) if @options[:bytes]
      file_info_hash[:file] = file
      file_info_hash
    end
  end

  def calc_stdin_display_width(stdin_info_array)
    stdin_info_array.map { |stdin_info| count_digits(stdin_info) }.max
  end

  def format_stdin_info_array_to_output_line(stdin_info_array, display_width)
    stdin_info_array.map { |stdin_info| format_number(stdin_info, display_width) }.join(' ')
  end

  def calc_file_display_width(file_info_hashes)
    FILE_INFO_KEYS.map do |key|
      next unless @options[key]

      file_info_hashes
        .select { |file_info_hash| file_info_hash[key] } # 値のある要素だけを選択
        .map { |file_info_hash| count_digits(file_info_hash[key]) }
        .max
    end.compact.max
  end

  def calc_total(file_info_hashes)
    total_hash = { file: 'total' }
    FILE_INFO_KEYS.each do |key|
      next unless @options[key]

      total_hash[key] = file_info_hashes
                        .select { |file_info_hash| file_info_hash[key] } # 値のある要素だけを選択
                        .sum { |file_info_hash| file_info_hash[key] }
    end
    total_hash
  end

  def format_file_info_hashes_to_output_lines(file_info_hashes, display_width)
    output_lines = []
    file_info_hashes.each do |file_info_hash|
      output_lines << file_info_hash[:message] if file_info_hash[:message]
      next unless file_info_hash[:file]

      output_line = FILE_INFO_KEYS.map do |key|
        next unless file_info_hash[key]

        format_number(file_info_hash[key], display_width)
      end.compact.join(' ')
      output_line += " #{file_info_hash[:file]}"
      output_lines << output_line
    end
    output_lines
  end

  def count_file_lines_num(file)
    return 0 if FileTest.directory?(file)

    line_count = 0
    File.open(file) { |f| f.each_line { line_count += 1 } }
    line_count
  end

  def count_file_bytesize(file)
    return 0 if FileTest.directory?(file)

    file_path = Pathname.new(file)
    file_path.lstat.size
  end

  def count_file_words_num(file)
    return 0 if FileTest.directory?(file)

    word_count = 0
    File.open(file) { |f| f.each_line { |line| word_count += line.split.compact.length } }
    word_count
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
