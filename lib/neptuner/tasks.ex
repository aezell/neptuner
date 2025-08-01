defmodule Neptuner.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias Neptuner.Repo

  alias Neptuner.Tasks.Task

  def list_tasks(user_id) do
    Task
    |> where([t], t.user_id == ^user_id)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  def list_tasks_by_status(user_id, status) do
    Task
    |> where([t], t.user_id == ^user_id and t.status == ^status)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  def list_tasks_by_cosmic_priority(user_id, cosmic_priority) do
    Task
    |> where([t], t.user_id == ^user_id and t.cosmic_priority == ^cosmic_priority)
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  def list_tasks_for_date_range(user_id, start_date, end_date) do
    start_datetime = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_datetime = DateTime.new!(end_date, ~T[23:59:59], "Etc/UTC")

    Task
    |> where([t], t.user_id == ^user_id)
    |> where(
      [t],
      (not is_nil(t.due_date) and t.due_date >= ^start_date and t.due_date <= ^end_date) or
        (t.inserted_at >= ^start_datetime and t.inserted_at <= ^end_datetime) or
        (not is_nil(t.completed_at) and t.completed_at >= ^start_datetime and
           t.completed_at <= ^end_datetime)
    )
    |> order_by([t], desc: t.inserted_at)
    |> Repo.all()
  end

  def get_tasks_by_priority_distribution(user_id, start_date, end_date) do
    tasks = list_tasks_for_date_range(user_id, start_date, end_date)

    tasks
    |> Enum.group_by(& &1.cosmic_priority)
    |> Enum.map(fn {priority, tasks} -> {priority, length(tasks)} end)
    |> Enum.into(%{})
  end

  def get_task!(id), do: Repo.get!(Task, id)

  def get_user_task!(user_id, id) do
    Task
    |> where([t], t.user_id == ^user_id and t.id == ^id)
    |> Repo.one!()
  end

  def create_task(user_id, attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
    |> Repo.insert()
  end

  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  def complete_task(%Task{} = task) do
    update_task(task, %{status: :completed})
  end

  def abandon_task(%Task{} = task) do
    update_task(task, %{status: :abandoned_wisely})
  end

  def get_task_statistics(user_id) do
    tasks = list_tasks(user_id)

    %{
      total: length(tasks),
      completed: length(Enum.filter(tasks, &(&1.status == :completed))),
      pending: length(Enum.filter(tasks, &(&1.status == :pending))),
      abandoned_wisely: length(Enum.filter(tasks, &(&1.status == :abandoned_wisely))),
      matters_10_years: length(Enum.filter(tasks, &(&1.cosmic_priority == :matters_10_years))),
      matters_10_days: length(Enum.filter(tasks, &(&1.cosmic_priority == :matters_10_days))),
      matters_to_nobody: length(Enum.filter(tasks, &(&1.cosmic_priority == :matters_to_nobody)))
    }
  end
end
