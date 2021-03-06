class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Associations
  has_many :tasks, dependent: :destroy

  # Validations
  validates :username, :first_name, presence: true
  validates :username, :first_name, length: { minimum: 2 }
  validates :username, :email, uniqueness: true
  validates :last_name, length: { minimum: 2 }, allow_blank: true
end
