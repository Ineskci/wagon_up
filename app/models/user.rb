class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :analyses, dependent: :destroy
  has_many :roles, through: :analyses

  validates :name, presence: true
end
