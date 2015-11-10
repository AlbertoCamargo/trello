class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :user,        index: true, foreign_key: true, null: false
      t.string     :title,       null: false
      t.boolean    :finished,    null:false,  default: false
      t.integer    :duration,    null: false, default: 0
      t.date       :start_date,  null: false
      t.date       :finish_date, null: false
      t.text       :description

      t.timestamps null: false
    end
  end
end
