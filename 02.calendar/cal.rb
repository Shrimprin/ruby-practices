#!/usr/bin/env ruby
require 'optparse'
require 'date'

#-----カレンダーに表示する年月を決める
#デフォルトは今日の年、月
Time.now => { year:, month:}
#オプションが有れば上書きする
opt = OptionParser.new
opt.banner = "Usage: calender.rb [options]"
opt.on('-y' , '--year YEAR', Integer,'Specify the year.'){|y| year = y}
opt.on('-m', '--month MONTH', Integer, 'Specify the month.'){|m| month = m}
opt.parse!(ARGV)

#-----カレンダーを表示する
first_day = Date.new(year, month, 1)
last_day = Date.new(year, month, -1)
print "      \e[35m#{month}\e[0m月 \e[35m#{year}\e[0m\n"
print "日 月 火 水 木 金 土 \n"
print '   ' * first_day.wday
(first_day..last_day).each do |d|
  printf('%2s',(d == Date.today ? "\e[36m#{d.day}\e[0m" : d.day))
  print(d.saturday? ? "\n" : ' ')
end
