# frozen_string_literal: true

require './frame'

class Game
  STRIKE_MARK = 'X'

  def initialize(marks)
    @frames = []
    frame = []
    marks.each do |mark|
      frame << mark
      # 最終フレームはループ後に@framesに格納するため、次のループへ
      next if @frames.size == 9

      # フレーム内のショット数が2またはストライクならば、@framesに格納
      next unless frame.size == 2 || mark == STRIKE_MARK

      @frames << Frame.new(*frame)
      frame.clear
    end
    # 最終フレーム
    @frames << Frame.new(*frame)
  end

  def score
    score = 0
    10.times do |number|
      frame, next_frame, after_next_frame = @frames.slice(number, 3)
      left_shots = [next_frame&.shots, after_next_frame&.shots].compact.flatten

      score += if frame.strike?
                 frame.score + left_shots.slice(0, 2).sum(&:score)
               elsif frame.spare?
                 frame.score + left_shots[0].score
               else
                 frame.score
               end
    end
    score
  end
end
