# frozen_string_literal: true

require_relative './file_item'

class DirItem
  attr_reader :name, :file_items

  def initialize(dir, all_option)
    @name = dir
    files = collect_files(dir, all_option)
    @file_items = files.map { |file| FileItem.new(file) }
  end

  private

  def collect_files(dir, all_option)
    dotmatch_option = all_option ? File::FNM_DOTMATCH : 0
    Dir.glob("#{dir}/*", flags: dotmatch_option)
  end
end
