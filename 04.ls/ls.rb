#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

class LsCommand
  COLUMNS_NUM = 3 # 表示する列数

  # 対象ディレクトリとその中のファイルをそれぞれクラス変数に格納する
  def initialize(file, options)
    @is_all = true if options[:all]
    @file = file
    @files = list_files
  end

  def list_files
    if FileTest.directory? @file
      if @is_all
        Dir.glob("#{@file}/*", File::FNM_DOTMATCH).map { |file| File.basename(file) }
      else
        Dir.glob("#{@file}/*").map { |file| File.basename(file) }
      end
    else
      [File.basename(@file)]
    end
  end

  def sort_files
    @files.sort!
  end

  def display_files
    exit if @files.empty?
    display_data = create_display_data
    display_data.each do |row|
      puts row
    end
  end

  # 表示する行の配列を返す
  def create_display_data
    # 表示幅がウィンドウ幅を上回る場合は表示列数を減らす
    window_width = `tput cols`.to_i
    display_width = window_width + 1
    cut_columns_num = 0 # 減らす列数
    until display_width <= window_width
      columns_num = COLUMNS_NUM - cut_columns_num
      break if columns_num < 1 # 列数が1でもウィンドウ幅を超えるなら仕方ないのでそのまま

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

  # ファイル一覧を列ごとの配列にして返す
  def store_files_in_column(columns_num)
    # 各列の要素数を計算
    quote = (@files.length / columns_num).floor
    remain = @files.length % columns_num
    file_num_per_column = (remain.positive? ? quote + 1 : quote)
    files = []
    columns_num.times do |column_index|
      start_index = file_num_per_column * column_index
      break if start_index >= @files.length

      end_index = file_num_per_column * (column_index + 1) - 1
      end_index = @files.length - 1 if end_index >= @files.length
      files <<
        (start_index..end_index).map do |file_index|
          @files[file_index]
        end
    end
    files # breakで抜けた際にもfilesを返せるように
  end

  def calc_columns_width(columns)
    columns.map do |column|
      max_width = 0
      column.each do |file|
        file_width = count_character(file)
        max_width = file_width if file_width > max_width
      end
      max_width
    end
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
    padding = padding_char * (padding_length / count_character(padding_char))
    str + padding
  end
end

options = {}
opt = OptionParser.new
opt.banner = 'Usage: ls.rb [options]'
opt.on('-a', '--all', 'do not ignore entries starting with .') { options[:all] = true }
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
