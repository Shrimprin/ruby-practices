#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

require_relative './dir_item'
require_relative './short_display_format'
require_relative './long_display_format'

class LsCommand
  def initialize(opt)
    @options = { long: false, reverse: false, all: false }
    opt.banner = 'Usage: ls.rb [options]'
    opt.on('-l', 'use a long listing format.') { @options[:long] = true }
    opt.on('-r', '--reverse', 'reverse order while sorting.') { @options[:reverse] = true }
    opt.on('-a', '--all', 'do not ignore entries starting with .') { @options[:all] = true }
    opt.parse!(ARGV) # opt.onメソッドで定義したブロックを実行し、ARGVからそのオプション部分を取り除く

    exist_items, @non_exist_items = ARGV.partition { |item| File.exist?(item) }
    dirs, files = exist_items.partition { |item| File.directory?(item) }
    dirs << Dir.pwd if dirs.empty? && files.empty?
    @dir_items = dirs.map { |dir| DirItem.new(dir, @options[:all]) }
    @file_items = files.map { |file| FileItem.new(file) }
  end

  def show
    display_format_class = @options[:long] ? LongDisplayFormat : ShortDisplayFormat
    display_format = display_format_class.new(@dir_items, @file_items, @non_exist_items, @options)
    puts display_format.result
  end
end

opt = OptionParser.new
ls_command = LsCommand.new(opt)
ls_command.show
