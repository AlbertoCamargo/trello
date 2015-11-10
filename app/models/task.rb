class Task < ActiveRecord::Base

  # Validations
  validates          :user, :title, presence: true
  validates          :finished, inclusion: { in: [true, false] }
  validates          :duration, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates_datetime :finish_date, on_or_after: :start_date

  # Associations
  belongs_to :user

  # Callback
  before_save :format_attribute

  # -------------- Private ----------------
  private
  def format_attribute
    self.title.capitalize!
  end
end
