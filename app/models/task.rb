class Task < ActiveRecord::Base

  # Validations
  validates          :user, :title, presence: true
  validates          :finished, inclusion: { in: [true, false] }
  validates_datetime :finish_date, on_or_after: :start_date
  validates_time     :duration, allow_blank: true

  # Associations
  belongs_to :user

  # Callback
  before_save :format_attribute


  def format_attribute
    self.title.capitalize!
  end
end
