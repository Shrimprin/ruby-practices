#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

require_relative './dir_item'
require_relative './display_data'
require_relative './long_display_data'

class LsCommand
  def initialize(opt)
    @options = { long: false, reverse: false, all: false }
    opt.banner = 'Usage: ls.rb [options]'
    opt.on('-l', 'use a long listing format.') { @options[:long] = true }
    opt.on('-r', '--reverse', 'reverse order while sorting.') { @options[:reverse] = true }
    opt.on('-a', '--all', 'do not ignore entries starting with .') { @options[:all] = true }
    opt.parse!(ARGV) # opt.onメソッドで定義したブロックを実行し、ARGVからそのオプション部分を取り除く
    dirs = ARGV
    dirs << Dir.pwd if dirs.empty?

    @dir_items = dirs.map { |dir| DirItem.new(dir, @options[:all]) }
  end

  def show
    display_data = @options[:long] ? LongDisplayData.new(@dir_items, @options) : DisplayData.new(@dir_items, @options)
    puts display_data.result
  end
end

opt = OptionParser.new
ls_command = LsCommand.new(opt)
ls_command.show
