#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'pathname'

class LsCommand
  COLUMNS_NUM = 3 # 表示する列数
  # 初期化関数
  # 対象ディレクトリとその中のファイルをそれぞれクラス変数に格納する
  def initialize(dir)
    @item_array = get_items(dir)
    @dir = dir
  end

  # 対象ディレクトリ内のファイル一覧を取得して配列で返す
  def get_items(dir)
    Dir.glob("#{dir}/*").map { |path| File.basename(path) }
  end

  # ファイル一覧をソートする
  def sort_items
    @item_array.sort!
  end

  # ファイル一覧を表示する
  def display_items
    # ディレクトリ内にファイルがないなら抜ける
    exit if @item_array.empty?

    # 表示するデータを行ごとの配列で取得する
    rows_array = create_display_data

    # 表示する
    puts @dir
    rows_array.each do |row|
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
      columns_array = store_items_in_column(columns_num)

      # 各列の最大幅を取得
      columns_width = calc_columns_width(columns_array)

      # 表示する列の幅を計算（列間スペースを含める）
      display_width = columns_width.sum + (2 * (columns_num - 1))
      cut_columns_num += 1
    end

    # 列ごとの行列を行ごとの配列に変える
    unite_columns_to_rows(columns_array, columns_width)
  end

  # ファイル一覧を列ごとの配列にして返す
  def store_items_in_column(columns_num)
    # 各列の要素数を計算
    quote = (@item_array.length / columns_num).floor
    remain = @item_array.length % columns_num
    item_num_per_column = (remain.positive? ? quote + 1 : quote)

    # 列ごとの配列を作成
    columns_array = []
    columns_num.times do |column_index|
      start_index = item_num_per_column * column_index
      break if start_index >= @item_array.length

      end_index = item_num_per_column * (column_index + 1) - 1
      end_index = @item_array.length - 1 if end_index >= @item_array.length

      column = []
      (start_index..end_index).each do |item_index|
        column << @item_array[item_index]
      end
      columns_array << column
    end
    columns_array
  end

  # 表示する列の幅を決めて配列にして返す
  def calc_columns_width(columns_array)
    columns_width = []
    columns_array.each do |column|
      max_width = 0
      column.each do |item|
        item_width = count_character(item)
        max_width = item_width if item_width > max_width
      end
      columns_width << max_width
    end
    columns_width
  end

  # 列を行ごとに結合して配列で返す
  def unite_columns_to_rows(columns_array, columns_width)
    rows_array = []
    rows_num = columns_array[0].length # 列の中の要素数が行数となる
    rows_num.times do |row_index|
      row = ''
      columns_array.each_with_index do |column, column_index|
        break if !column[row_index] # 要素が無ければループを抜ける

        row += custom_rjust(column[row_index], columns_width[column_index] + 2) # +2は隣の行とのスペースのため
      end
      row.rstrip!
      rows_array << row
    end
    rows_array
  end

  # 文字数を返す
  def count_character(str)
    count = 0
    str.chars.each do |char|
      count += (char.bytesize == 1 ? 1 : 2)
    end
    count
  end

  # rjustメソッドの改良版
  # 半角を1文字・全角を2文字でカウントして右埋めする
  def custom_rjust(str, target_length, padding_char = ' ')
    str_length = count_character(str)
    padding_length = target_length - str_length
    padding = padding_char * (padding_length / count_character(padding_char))
    str + padding
  end
end

# 対象のディレクトリを受け取る
dir_array = ARGV

# ディレクトリの指定がないならカレントディレクトリを指定する
dir_array << Dir.pwd if dir_array.empty?

# 全ての対象ディレクトリに対してlsコマンドを実行する
dir_array.each do |dir|
  # 指定したディレクトリが存在するか確認
  path = Pathname.new(dir)
  unless path.exist?
    puts "指定したディレクトリが見つかりません：#{path}"
    next
  end
  # 指定したディレクトリが相対パスなら絶対パスにする
  path = path.realpath

  # lsコマンド実行
  ls = LsCommand.new(path)
  ls.sort_items
  ls.display_items
  puts # 出力結果の可読性のために空行を出力
end
