# frozen_string_literal: true

require './frame'

class Game
  def initialize(marks)
    @frames = []
    frame = []
    marks.each do |mark|
      frame << mark
      # 最終フレームのショット数は最大3となるため、ループ後に@framesに格納
      next if @frames.size == 9

      # フレーム内のショット数が2またはストライクならば、@framesに格納
      next unless frame.size == 2 || mark == 'X'

      @frames << Frame.new(*frame)
      frame.clear
    end
    # 最終フレーム
    @frames << Frame.new(*frame)
  end

  def score
    score = 0
    (0..9).each do |i|
      frame, next_frame, after_next_frame = @frames.slice(i, 3)
      next_shots = next_frame.nil? ? [] : next_frame.shots
      after_next_shots = after_next_frame.nil? ? [] : after_next_frame.shots
      left_shots = next_shots + after_next_shots

      if frame.strike?
        score += frame.score + left_shots.slice(0, 2).sum(&:score)
      elsif frame.spare?
        score += frame.score + left_shots[0].score
      else
        score += frame.score
      end
    end
    score
  end
end
