# frozen_string_literal: true

require_relative './display_format'

class LongDisplayFormat < DisplayFormat
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

  private

  def format(file_items)
    rows = []
    if file_items.length > 1
      total_blocks = count_total_blocks(file_items)
      rows << "total #{total_blocks}"
    end

    max_char_lengths = find_max_char_lengths(file_items)
    rows <<
      file_items.map do |file_item|
        build_row(file_item, *max_char_lengths)
      end
  end

  def count_total_blocks(file_items)
    # File.statで割り当てられるブロック数が512バイトであるのに対し、
    # Linuxのデフォルトのブロック数は1024バイト。そのままではOS標準の2倍になるため1/2する
    # MacOSは512バイトのためそのままOK
    file_items.map do |file_item|
      file_item.stat[:blocks]
    end.sum
  end

  def find_max_char_lengths(file_items)
    %i[link_num owner group size].map do |key|
      file_items.map do |file_item|
        file_item.stat[key].to_s.length
      end.max
    end
  end

  def build_row(file_item, link_num_char_length, owner_char_length, group_char_length, size_char_length)
    file_item_stat = file_item.stat
    type = file_item_stat[:type]
    type_mark = convert_ftype_to_mark(type)
    permissions = convert_mode_to_permissions(file_item_stat[:mode])
    link_num = file_item_stat[:link_num].to_s.rjust(link_num_char_length)
    owner = file_item_stat[:owner].ljust(owner_char_length)
    group = file_item_stat[:group].ljust(group_char_length)
    time = file_item_stat[:time]
    name = file_item_stat[:name]

    if %w[characterSpecial blockSpecial].include?(type)
      rdev = file_item_stat[:rdev]
      "#{type_mark}#{permissions} #{link_num} #{owner} #{group} #{rdev} #{time} #{name}"
    else
      size = file_item_stat[:size].to_s.rjust(size_char_length)
      "#{type_mark}#{permissions} #{link_num} #{owner} #{group} #{size} #{time} #{name}"
    end
  end

  def convert_ftype_to_mark(type)
    FILE_TYPES[type]
  end

  def convert_mode_to_permissions(mode)
    mode.to_s(8).chars[-3..].map { |num| PERMISSIONS[num.to_i] }.join('')
  end
end
