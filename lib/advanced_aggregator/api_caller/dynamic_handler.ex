defmodule AdvancedAggregator.ApiCaller.DynamicHandler do
  @moduledoc """
  The dynamicHandle module is a task.supervisor. When invocked, it receive a list of social_media and create children based on them
  """
  # use Task.Supervisor

  alias AdvancedAggregator.ApiCaller.Caller

  def start_link(_) do
    Task.Supervisor.start_link(name: :caller_dynamic_handler)
  end

  def start_child([], _), do: :ok

  def start_child([head | tail], supervisor) do
    supervisor
    |> Task.Supervisor.async(Caller, :get_post_from_social_media, [head], restart: :transient)

    start_child(tail, supervisor)
  end
end
