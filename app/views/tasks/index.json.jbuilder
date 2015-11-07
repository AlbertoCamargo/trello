json.array!(@tasks) do |task|
  json.extract! task, :id, :user_id, :title, :description, :duration, :start_date, :finish_date, :finished
  json.url task_url(task, format: :json)
end
