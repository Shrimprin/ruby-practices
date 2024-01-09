# frozen_string_literal: true

class DisplayFormat
  def initialize(dir_items, file_items, non_exist_items, options)
    @dir_items = dir_items
    @file_items = file_items
    @non_exist_items = non_exist_items
    @options = options
  end

  def result
    formatted_data =
      sort_non_exist_items.map do |non_exist_item|
        "ls: #{non_exist_item}: No such file or directory"
      end

    unless @file_items.empty?
      formatted_data << format(sort_file_items(@file_items))
      formatted_data << "\n"
    end

    dir_name_flag = @dir_items.length >= 2 || !@file_items.empty?

    sort_dir_items.each do |dir_item|
      formatted_data << "#{dir_item.name}:" if dir_name_flag
      file_items = dir_item.file_items
      next if file_items.empty?

      sorted_file_items = sort_file_items(dir_item.file_items)
      formatted_data << format(sorted_file_items)
      formatted_data << "\n"
    end
    formatted_data
  end

  private

  def sort_non_exist_items
    @non_exist_items.sort
  end

  def sort_dir_items
    sorted_dir_items = @dir_items.sort_by(&:name)
    @options[:reverse] ? sorted_dir_items.reverse : sorted_dir_items
  end

  def sort_file_items(file_items)
    sorted_file_items = file_items.sort_by { |file_item| file_item.stat[:name] }
    @options[:reverse] ? sorted_file_items.reverse : sorted_file_items
  end
end
