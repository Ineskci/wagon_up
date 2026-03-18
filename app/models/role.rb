class Role < ApplicationRecord
  belongs_to :analysis
  has_many :interviews, dependent: :destroy
  has_one :user, through: :analysis

  validates :title, presence: true
  validates :position, presence: true, inclusion: { in: 1..3 }
end
