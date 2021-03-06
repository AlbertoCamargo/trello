class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    #@tasks = Task.all
    @due_tasks = Task.where("finish_date < ? AND finished = ?", Date.today, false).order(:finish_date)
    #Task.where("finish_date >= ? AND finished = ?" , Time.now, false).order(:finish_date)
    @tasks = Task.where(finished: false).order(:finish_date) - @due_tasks
    @finished_tasks = Task.where(finished: true).order(finish_date: :desc)
    @task = Task.new
  end

  def show
    respond_to do |format|
      format.js
    end
  end

  def new
    @task = current_user.tasks.build
  end

  def edit
  end

  def create
    @task = current_user.tasks.build(task_params)

    respond_to do |format|
      if @task.save
        format.html { redirect_to :tasks }
        format.json { render :show, status: :created, location: @task }
      else
        format.html { render :new }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to :tasks }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @task.destroy
    respond_to do |format|
      format.html { redirect_to tasks_url, notice: 'Task was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_task
      @task = Task.find(params[:id])
    end

    def task_params
      params.require(:task).permit(:user_id, :title, :description, :duration, :start_date, :finish_date, :finished)
    end
end
