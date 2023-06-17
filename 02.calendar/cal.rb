require 'optparse'
require 'date'

#-----カレンダーに表示する年月を決める
#デフォルトは今日の年、月
year = Date.today.year
month = Date.today.month
#オプションが有れば上書きする
opt = OptionParser.new
opt.banner = "Usage: calender.rb [options]"
opt.on('-y' , '--year YEAR', Integer,'Specify the year.'){|y| year = y}
opt.on('-m', '--month MONTH', Integer, 'Specify the month.'){|m| month = m}
opt.parse!(ARGV)

#-----カレンダーを表示する
print "      \e[35m#{month}\e[0m月 \e[35m#{year}\e[0m\n"
print "日 月 火 水 木 金 土 \n"
print '   ' * Date.new(year, month, 1).wday
last_day = Date.new(year, month, -1).day
(1..last_day).each do |d|
  date = Date.new(year,month,d)
  printf('%2s',(date == Date.today ? "\e[36m#{d}\e[0m" : d))
  print(Date.new(year,month,d).wday == 6 ? "\n" : ' ')
end
