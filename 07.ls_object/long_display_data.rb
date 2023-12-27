# frozen_string_literal: true

class LongDisplayData < DisplayData
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

  FILE_SIZE_COLUMUNS = 4

  private

  def format(file_items)
    rows = []
    if file_items.length > 1
      total_blocks = count_total_blocks(file_items)
      rows << "total #{total_blocks}"
    end

    owner_char_length = count_owner_char_length(file_items)
    group_char_length = count_group_char_length(file_items)

    rows <<
      file_items.map do |file_item|
        build_row(file_item, owner_char_length, group_char_length)
      end
  end

  def count_total_blocks(file_items)
    # File.statで割り当てられるブロック数が512バイトであるのに対し、
    # Linuxのデフォルトのブロック数は1024バイト。そのままではOS標準の2倍になるため1/2する
    # MacOSの512バイトのためそのままOK
    file_items.map do |file_item|
      file_item.stat[:blocks]
    end.sum
  end

  # オーナー名の幅を揃えるため、ディレクトリ内のオーナー名の最長文字数を取得する
  def count_owner_char_length(file_items)
    file_items.map do |file_item|
      owner = file_item.stat[:owner]
      owner.length
    end.max
  end

  # グループ名の幅を揃えるため、ディレクトリ内のグループ名の最長文字数を取得する
  def count_group_char_length(file_items)
    file_items.map do |file_item|
      group = file_item.stat[:group]
      group.length
    end.max
  end

  def build_row(file_item, owner_char_length, group_char_length)
    type = file_item.stat[:type]
    type_mark = conver_ftype_to_mark(type)
    permissions = convert_mode_to_permissions(file_item.stat[:mode])
    link_num = file_item.stat[:link_num]
    owner = file_item.stat[:owner].ljust(owner_char_length)
    group = file_item.stat[:group].ljust(group_char_length)
    time = file_item.stat[:time]
    name = file_item.stat[:name]

    if %w[characterSpecial blockSpecial].include?(type)
      rdev = file_item.stat[:rdev]
      "#{type_mark}#{permissions} #{link_num} #{owner} #{group} #{rdev} #{time} #{name}"
    else
      size = file_item.stat[:size].to_s.rjust(FILE_SIZE_COLUMUNS)
      "#{type_mark}#{permissions} #{link_num} #{owner} #{group} #{size} #{time} #{name}"
    end
  end

  def conver_ftype_to_mark(type)
    FILE_TYPES[type]
  end

  def convert_mode_to_permissions(mode)
    mode.to_s(8).chars[-3..].map { |num| PERMISSIONS[num.to_i] }.join('')
  end
end
