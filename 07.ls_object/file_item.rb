# frozen_string_literal: true

require 'pathname'
require 'etc'

class FileItem
  attr_reader :path

  def initialize(dir, file)
    @path = Pathname.new(dir) + file
  end

  def stat
    @stat.nil? ? @stat = build_stat : @stat
  end

  private

  def build_stat
    file_stat = @path.lstat
    type = file_stat.ftype
    mode = file_stat.mode
    link_num = file_stat.nlink
    owner = Etc.getpwuid(file_stat.uid).name
    group = Etc.getgrgid(file_stat.gid).name
    rdev = "#{file_stat.rdev_major}, #{file_stat.rdev_minor}"
    size = file_stat.size
    time = file_stat.mtime.strftime('%b %d %H:%M')
    name = type == 'link' ? "#{file} -> #{@path.readlink}" : @path.basename.to_s
    blocks = file_stat.blocks

    {
      type:,
      mode:,
      link_num:,
      owner:,
      group:,
      rdev:,
      size:,
      time:,
      name:,
      blocks:
    }
  end

  ## パーミッションの表記を数字から文字列に変換する
  def convert_mode_to_permission(file_stat)
    mode = file_stat.mode.to_s(8)
    mode.chars[-3..].map { |num| PERMISSIONS[num.to_i] }.join('')
  end
end
