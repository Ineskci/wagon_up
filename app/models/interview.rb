class Interview < ApplicationRecord
  belongs_to :role
  has_many :answers, dependent: :destroy
  has_one :analysis, through: :role
  has_one :user, through: :analysis

  validates :category, presence: true
  validates :overall_score, numericality: { in: 0..100 }, allow_nil: true
end
