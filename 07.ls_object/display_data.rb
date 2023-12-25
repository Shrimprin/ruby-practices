# frozen_string_literal: true

class DisplayData
  COLUMNS_NUM = 3 # 表示する列数
  COLUMNS_SPACING = 2

  def initialize(dir_items, options)
    @dir_items = dir_items
    @options = options
  end

  def result
    formatted_data = []
    sort_dir_items.each do |dir_item|
      formatted_data << "#{dir_item.name}:" if @dir_items.length >= 2
      file_items = dir_item.file_items
      next if file_items.empty?

      sorted_file_items = sort_file_items(dir_item.file_items)
      formatted_data << format(sorted_file_items)
      formatted_data << "\n"
    end
    formatted_data
  end

  private

  def sort_dir_items
    sorted_dir_items = @dir_items.sort_by { |dir_item| dir_item.name }
    @options[:reverse] ? sorted_dir_items.reverse : sorted_dir_items
  end

  def sort_file_items(file_items)
    sorted_file_items = file_items.sort_by { |file_item| file_item.stat[:name] }
    @options[:reverse] ? sorted_file_items.reverse : sorted_file_items
  end

  def format(file_items)
    # 表示幅がウィンドウ幅を上回る場合は表示列数を減らす
    window_width = `tput cols`.to_i
    display_width = window_width + 1
    cut_columns_num = 0 # 減らす列数
    until display_width <= window_width || (COLUMNS_NUM - cut_columns_num) < 1 # 列数が1でもウィンドウ幅を超えるなら仕方ないのでそのまま
      columns_num = COLUMNS_NUM - cut_columns_num
      # 列ごとの配列を取得
      columns = store_files_in_column(file_items, columns_num)

      # 各列の最大幅を取得
      columns_width = calc_columns_width(columns)

      # 表示する列の幅を計算（列間スペースを含める）
      display_width = columns_width.sum + (COLUMNS_SPACING * (columns_num - 1))
      cut_columns_num += 1
    end

    # 列ごとの行列を行ごとの配列に変える
    unite_columns_to_rows(columns, columns_width)
  end

  # ファイル一覧を表示列ごとの配列にして返す
  def store_files_in_column(file_items, columns_num)
    file_num_per_column = (file_items.length / columns_num.to_f).ceil
    files = []
    columns_num.times do |column_index|
      start_index = file_num_per_column * column_index
      break if start_index >= file_items.length

      end_index = file_num_per_column * (column_index + 1) - 1
      end_index = file_items.length - 1 if end_index >= file_items.length
      files << (start_index..end_index).map { |file_index| file_items[file_index] }
    end
    files # breakで抜けた際にもfilesを返せるように
  end

  def calc_columns_width(columns)
    columns.map { |column| column.map { |file| count_character(file.stat[:name]) }.max }
  end

  # 列を行ごとに結合して配列で返す
  def unite_columns_to_rows(columns, columns_width)
    rows_num = columns[0].length # 列の中の要素数が行数となる
    (0..rows_num - 1).map do |row_index|
      columns.map.with_index do |column, column_index|
        next if !column[row_index]

        rjust_by_displayed_width(column[row_index].stat[:name], columns_width[column_index] + COLUMNS_SPACING)
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
end
