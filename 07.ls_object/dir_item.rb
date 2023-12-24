# frozen_string_literal: true

require_relative './file_item'

class DirItem
  attr_reader :name, :file_items

  def initialize(dir, all_option)
    @name = dir
    files = collect_files(dir, all_option)
    # TODO:存在しないフォルダの場合の例外処理を書く
    @file_items = files.map { |file| FileItem.new(dir, file) }
  end

  private

  def collect_files(dir, all_option)
    if FileTest.directory?(dir)
      dotmatch_option = all_option ? File::FNM_DOTMATCH : 0
      Dir.glob("#{dir}/*", dotmatch_option).map { |file| File.basename(file) }
    else
      [File.basename(dir)]
    end
  end

  def count_total_blocks(file_path_hash)
    @files.map do |file|
      file_path = file_path_hash[file]
      file_path.lstat.blocks
    end.sum / 2 # File.statで割り当てられるブロック数が512バイトであるのに対し、Linuxのデフォルトのブロック数は1024バイト。そのままではOS標準の2倍になるため1/2する
  end
end
