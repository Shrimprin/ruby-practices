# frozen_string_literal: true

require './shot'

class Frame
  attr_reader :shots

  def initialize(first_mark, second_mark = nil, third_mark = nil)
    first_shot = first_mark.nil? ? nil : Shot.new(first_mark)
    second_shot = second_mark.nil? ? nil : Shot.new(second_mark)
    third_shot = third_mark.nil? ? nil : Shot.new(third_mark)
    @shots = [first_shot, second_shot, third_shot].compact
  end

  def score
    @shots.sum(&:score)
  end

  def strike?
    @shots[0].score == 10
  end

  def spare?
    score == 10
  end
end
