#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'
require 'etc'

class LsCommand
  COLUMNS_NUM = 3 # 表示する列数
  PERMISSIONS = {
    7 => 'rwx',
    6 => 'rw-',
    5 => 'r-x',
    4 => 'r--',
    3 => '-wx',
    2 => '-w-',
    1 => '--x',
    0 => '---'
  }.freeze
  FILE_TYPES = {
    'file' => '-',
    'directory' => 'd',
    'link' => 'l',
    'fifo' => 'p',
    'characterSpecial' => 'c',
    'blockSpecial' => 'b',
    'socket' => 's'
  }.freeze
  # 対象ディレクトリとその中のファイルをそれぞれクラス変数に格納する
  def initialize(file, options)
    @is_long = true if options[:long]
    @file = file
    @files = list_files
  end

  def list_files
    if FileTest.directory? @file
      Dir.glob("#{@file}/*").map { |file| File.basename(file) }
    else
      [File.basename(@file)]
    end
  end

  def sort_files
    @files.sort!
  end

  def display_files
    exit if @files.empty?
    display_data = (@is_long ? create_display_data_long : create_display_data)
    display_data.each { |row| puts row }
  end

  # 表示する行の配列を返す（通常）
  def create_display_data
    # 表示幅がウィンドウ幅を上回る場合は表示列数を減らす
    window_width = `tput cols`.to_i
    display_width = window_width + 1
    cut_columns_num = 0 # 減らす列数
    until display_width <= window_width || (COLUMNS_NUM - cut_columns_num) < 1 # 列数が1でもウィンドウ幅を超えるなら仕方ないのでそのまま
      columns_num = COLUMNS_NUM - cut_columns_num
      # 列ごとの配列を取得
      columns = store_files_in_column(columns_num)

      # 各列の最大幅を取得
      columns_width = calc_columns_width(columns)

      # 表示する列の幅を計算（列間スペースを含める）
      display_width = columns_width.sum + (2 * (columns_num - 1))
      cut_columns_num += 1
    end

    # 列ごとの行列を行ごとの配列に変える
    unite_columns_to_rows(columns, columns_width)
  end

  # 表示する行の配列を返す（-lオプション用）
  def create_display_data_long
    rows = []
    if @files.length > 1
      total_blocks = count_total_blocks_in_dir
      rows << "total #{total_blocks}"
    end
    owner_char_length = count_owner_char_length
    group_char_length = count_group_char_length

    rows <<
      @files.map do |file|
        format_file_information(file, owner_char_length, group_char_length)
      end
  end

  def format_file_information(file, owner_char_length, group_char_length)
    file_path = @file.file? ? Pathname.new(@file) : Pathname.new(@file) + file
    file_stat = file_path.lstat
    file_type = file_stat.ftype
    file_type_mark = FILE_TYPES[file_type]
    file = "#{file} -> #{file_path.readlink}" if file_type == 'link'
    permissions = convert_mode_to_permission(file_stat)
    link_num = file_stat.nlink
    owner = Etc.getpwuid(file_stat.uid).name.ljust(owner_char_length)
    group = Etc.getgrgid(file_stat.gid).name.ljust(group_char_length)
    size = file_stat.size.to_s.rjust(4)
    time = file_stat.mtime.strftime('%b %d %H:%M')

    if %w[characterSpecial blockSpecial].include?(file_type)
      rdev = "#{file_stat.rdev_major}, #{file_stat.rdev_minor}"
      "#{file_type_mark}#{permissions} #{link_num} #{owner} #{group} #{rdev} #{time} #{file}"
    else
      "#{file_type_mark}#{permissions} #{link_num} #{owner} #{group} #{size} #{time} #{file}"
    end
  end

  # ファイル一覧を列ごとの配列にして返す
  def store_files_in_column(columns_num)
    file_num_per_column = (@files.length / columns_num.to_f).ceil
    files = []
    columns_num.times do |column_index|
      start_index = file_num_per_column * column_index
      break if start_index >= @files.length

      end_index = file_num_per_column * (column_index + 1) - 1
      end_index = @files.length - 1 if end_index >= @files.length
      files << (start_index..end_index).map { |file_index| @files[file_index] }
    end
    files # breakで抜けた際にもfilesを返せるように
  end

  def calc_columns_width(columns)
    columns.map { |column| column.map { |file| count_character(file) }.max }
  end

  # 列を行ごとに結合して配列で返す
  def unite_columns_to_rows(columns, columns_width)
    rows_num = columns[0].length # 列の中の要素数が行数となる
    (0..rows_num - 1).map do |row_index|
      columns.map.with_index do |column, column_index|
        next if !column[row_index]

        rjust_by_displayed_width(column[row_index], columns_width[column_index] + 2) # +2は隣の行とのスペースのため
      end.join('').rstrip
    end
  end

  def count_character(str)
    str.chars.sum { |char| char.bytesize == 1 ? 1 : 2 }
  end

  # rjustメソッドの改良版
  # 半角を1文字・全角を2文字でカウントして右埋めする
  def rjust_by_displayed_width(str, target_length, padding_char = ' ')
    str_length = count_character(str)
    padding_length = target_length - str_length
    str + padding_char * (padding_length / count_character(padding_char))
  end

  ## パーミッションの表記を数字から文字列に変換する
  def convert_mode_to_permission(file_stat)
    mode = file_stat.mode.to_s(8)
    mode.chars[-3..].map { |num| PERMISSIONS[num.to_i] }.join('')
  end

  def count_total_blocks_in_dir
    @files.map do |file|
      file_path = @file.file? ? Pathname.new(@file) : Pathname.new(@file) + file
      file_path.lstat.blocks
    end.sum / 2 # File.statで割り当てられるブロック数が512バイトであるのに対し、Linuxのデフォルトのブロック数は1024バイト。そのままではOS標準の2倍になるため1/2する
  end

  # lオプションで表示するオーナー名の幅を揃えるため、ディレクトリ内のオーナー名の最長文字数を取得する
  def count_owner_char_length
    @files.map do |file|
      file_path = @file.file? ? Pathname.new(@file) : Pathname.new(@file) + file
      file_stat = file_path.lstat
      owner = Etc.getpwuid(file_stat.uid).name
      owner.length
    end.max
  end

  # lオプションで表示するグループ名の幅を揃えるため、ディレクトリ内のグループ名の最長文字数を取得する
  def count_group_char_length
    @files.map do |file|
      file_path = @file.file? ? Pathname.new(@file) : Pathname.new(@file) + file
      file_stat = file_path.lstat
      group = Etc.getgrgid(file_stat.gid).name
      group.length
    end.max
  end
end

options = {}
opt = OptionParser.new
opt.banner = 'Usage: ls.rb [options]'
opt.on('-l', 'use a long listing format.') { options[:long] = true }
opt.parse!(ARGV)
files = ARGV
files << Dir.pwd if files.empty?

# 全ての対象ディレクトリに対してlsコマンドを実行する
files.each do |file|
  path = Pathname.new(file)
  unless path.exist?
    puts "指定したディレクトリが見つかりません：#{path}"
    next
  end

  path = path.realpath
  puts "#{file}:" if files.length > 1 && FileTest.directory?(file)
  ls = LsCommand.new(path, options)
  ls.sort_files
  ls.display_files
  puts # 出力結果の可読性のために空行を出力
end
