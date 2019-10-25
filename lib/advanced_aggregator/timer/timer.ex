defmodule AdvancedAggregator.Timer do
  @moduledoc """
  The timer module has for purpose to call every N secondes the caller supervisor and pass it a social_media list.
  N depends of the number of elements stored in the social_media_storage and other parameters such as:

    - :max_agent, which is one element to calcul the time between each call
    - :base_timer, which is a configuration base value,
      and is the time between the first and the second call of the same social_media agent, in milliseconds
    - :timer, which is the result of a division between the number of agents and the number of base_timer

  Outside of the base, it also use two `handle_cast/2` to update the `:timer`

  The first `handle_cast/2` handle the case where there is a new agent. It takes as parameter `:update_max_agent`.
  The second `handle_cast/2` handle the case where there is a new base_timer set. It takes as parameter a tuple with
    athe atom `:update_base_timer` and the new base timer.
  """

  use GenServer

  alias AdvancedAggregator.ApiCaller.DynamicHandler
  #   alias AdvancedAggregator.SocialMediaStorage.StorageTracker

  def start_link(_) do
    GenServer.start_link(__MODULE__, name: :aggregator_timer)
  end

  @impl true
  def init(_) do
    base_timer = Application.fetch_env!(:advanced_aggregator, :timer)

    new_state = %{
      agent: 0,
      max_agent: 0,
      base_timer: base_timer,
      timer: 0,
      init_completed: false
    }

    {:ok, new_state}
  end

  ############################################
  ### This is where the timer loop is done ###
  ############################################

  defp schedule_work(%{timer: timer}), do: Process.send_after(self(), :work, timer)

  @impl true
  def handle_info(:work, %{agent: agent, max_agent: max_agent} = state) do
    GenServer.call(:social_media_storage_tracker, :get_social_medias)
    |> DynamicHandler.start_child(:caller_dynamic_handler)

    new_state =
      if agent + 1 == max_agent do
        %{state | agent: 0}
      else
        %{state | agent: agent + 1}
      end

    schedule_work(new_state)
    {:noreply, new_state}
  end

  ###############################
  ### Other private functions ###
  ###############################

  @impl true
  def handle_cast(:complete_init, %{init_completed: true} = state), do: {:noreply, state}

  @impl true
  def handle_cast(:complete_init, %{base_timer: base_timer} = state) do
    %{workers: max_agent} = Supervisor.count_children(:social_media_storage_distributor)
    timer = calculate_timer(base_timer, max_agent)

    new_state = %{state | max_agent: max_agent, timer: timer, init_completed: true}
    schedule_work(new_state)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_max_agent, max_agent}, state) do
    timer = calculate_timer(state.base_timer, max_agent)

    {:noreply, %{state | timer: timer, max_agent: max_agent}}
  end

  @impl true
  def handle_cast({:update_base_timer, new_base_timer}, state) do
    new_timer = calculate_timer(new_base_timer, state.max_agent)

    {:noreply, %{state | timer: new_timer, base_timer: new_base_timer}}
  end

  defp calculate_timer(base_timer, max_agent) do
    div(base_timer, max_agent)
  end
end
