# frozen_string_literal: true

class Shot
  STRIKE_MARK = 'X'
  STRIKE_SCORE = 10

  def initialize(mark)
    @mark = mark
  end

  def score
    @mark == STRIKE_MARK ? 10 : @mark.to_i
    return 10 if @mark == STRIKE_MARK

    @mark.to_i
  end
end
