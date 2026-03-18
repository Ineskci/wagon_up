class Analysis < ApplicationRecord
  belongs_to :user
  has_many :roles, dependent: :destroy
  has_one_attached :file

  validates :cv_text, presence: true
end
