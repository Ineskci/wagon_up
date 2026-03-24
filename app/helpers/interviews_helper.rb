module InterviewsHelper
  def score_color_class(score)
    return "score-low" if score.nil? || score < 4
    return "score-mid" if score < 7
    "score-high"
  end
end
