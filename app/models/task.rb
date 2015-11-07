class Task < ActiveRecord::Base

  # Validations
  validates          :user, :title, presence: true
  validates          :finished, inclusion: { in: [true, false] }
  validates_datetime :finish_date, on_or_after: :start_date
  validates_time     :duration

  # Associations
  belongs_to :user
end
