class Interview < ApplicationRecord
  belongs_to :role
  has_many :answers, dependent: :destroy
  has_one :analysis, through: :role
  has_one :user, through: :analysis

  validates :category, presence: true
  validates :overall_score, numericality: { in: 0..100 }, allow_nil: true

  def avg_score
    scored = answers.where.not(score: nil)
    return 0.0 if scored.empty?
    (scored.sum(:score).to_f / scored.count).round(1)
  end

  def completed?
    answers.count >= 5
  end

  def finalize!
    avg = avg_score
    summary = if avg >= 7
      "Excelente desempenho! Demonstraste bom conhecimento técnico e comunicaste bem a tua experiência."
    elsif avg >= 4
      "Desempenho razoável. Há margem para melhorar — pratica mais e usa sempre o método STAR."
    else
      "Desempenho fraco. Não desanimes — pratica mais, prepara exemplos concretos e volta a tentar."
    end
    update!(overall_score: avg.round, feedback_summary: summary)
  end
end
