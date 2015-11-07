class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :user,        index: true, foreign_key: true, null: false
      t.string     :title,       null: false
      t.boolean    :finished,    null:false, default: false
      t.text       :description
      t.date       :start_date
      t.date       :finish_date
      t.time       :duration

      t.timestamps null: false
    end
  end
end
