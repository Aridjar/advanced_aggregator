defmodule AdvancedAggregator.SocialMediaStorage.StorageTracker do
  @moduledoc """
  The purpose of the storage_tracker is to follow the evolution of the Storage,
  from a new social media to the next agent to be called.

  To do so, it handle multiple calls and cast, and is registered to a webhook named `:webhook`

  The `handle_call/3` are:
    - [:get_agent | {:get_agent, number}] where the number is the position of the agent in the list.
      It returns the pid of the agent in the N position, or the first if no number are passed.
    - [:get_social_medias | {:get_social_medias, number}] where the number is the position of the agent in the list
      It returns a list of social_medias from the agent in the selected position, or the first if no number are passed.
    - :pop_agent, which returns the pid of the poped agent and change the state of the storage_tracker

  the `handle_cast/2` are:
    - :append_pop_agent, which put the first agent in the end of the list and update the state
    - :add_new_social_media, which handle the assignement of a social_media to an Agent

    # TODO : add an update function
    # TODO : add a remove function
  """

  use GenServer

  alias AdvancedAggregator.SocialMediaStorage.Storage

  def start_link(_) do
    GenServer.start_link(__MODULE__, name: :social_media_storage_tracker)
  end

  @impl true
  def init(_) do
    new_state = %{
      agents: [],
      max_agent: 0,
      min_agent_size: Application.fetch_env!(:advanced_aggregator, :min_social_media),
      max_agent_size: Application.fetch_env!(:advanced_aggregator, :max_social_media),
      init_completed: false
    }

    {:ok, new_state}
  end

  # Each handle_call as it own associated function

  @impl true
  def handle_call({:get_agent, agent_position}, _, state), do: get_agent(agent_position, state)
  @impl true
  def handle_call(:get_agent, _, state), do: get_agent(0, state)

  @impl true
  def handle_call(:get_social_medias, _, state), do: get_social_medias(0, state)
  @impl true
  def handle_call({:get_social_medias, agent_position}, _, state),
    do: get_social_medias(agent_position, state)

  @impl true
  def handle_call(:pop_agent, _, state), do: pop_and_return_social_medias(state)

  #############################
  ### handle_call functions ###
  #############################

  defp get_agent(agent_position, %{agents: agents} = state) do
    {_, pid, _, _} = Enum.at(agents, agent_position)

    {:reply, pid, state}
  end

  defp get_social_medias(agent_position, state) do
    social_medias =
      agent_position
      |> get_agent(state)
      |> elem(1)
      |> Storage.all()

    {:reply, social_medias, state}
  end

  defp pop_and_return_social_medias(state) do
    {_, return, _} = get_agent(0, state)
    {_, new_state} = append_pop_agent(state)
    {:reply, return, new_state}
  end

  # Each handle_cast as it own associated function

  @impl true
  def handle_cast(:complete_init, %{init_completed: true} = state), do: {:noreply, state}
  def handle_cast(:complete_init, state), do: complete_init(state)

  @impl true
  def handle_cast(:append_pop_agent, state), do: append_pop_agent(state)

  @impl true
  def handle_cast({:add_new_social_media, social_media}, state),
    do: add_new_social_media(social_media, state)

  #############################
  ### handle_cast functions ###
  ############################# *

  defp complete_init(state) do
    agents =
      Supervisor.which_children(:social_media_storage_distributor)
      |> Enum.reverse()

    max_agent = length(agents)
    {:noreply, %{state | agents: agents, max_agent: max_agent, init_completed: true}}
  end

  defp append_pop_agent(%{agents: agents} = state) do
    {head, tail} = List.pop_at(agents, 0)
    new_agents = tail ++ [head]

    new_state = %{state | agents: new_agents}

    {:noreply, new_state}
  end

  # TODO : rework this function
  defp add_new_social_media(social_media, state) do
    average_length_update = calculate_average_length_update(state)

    {_, first_agent, _} = get_agent(0, state)
    {_, second_agent, _} = get_agent(1, state)

    length_first_agent = Storage.count(first_agent)
    length_second_agent = Storage.count(second_agent)

    # TODO : rename the function and reduce the size it take
    new_state =
      case get_social_media_agent(
             length_first_agent,
             length_second_agent,
             average_length_update,
             state
           ) do
        :create ->
          create_new_storage_agent(first_agent, second_agent, social_media, state)

        :put_first ->
          Storage.put(first_agent, social_media.id, social_media)
          state

        :put_second ->
          Storage.put(second_agent, social_media.id, social_media)
          state
      end

    {:noreply, new_state}
  end

  defp calculate_average_length_update(state),
    do: (state.max_agent_size * 2 + state.min_agent_size) |> div(3)

  # get_social_media_agent as for purpose to define where to assign the new social_media.
  # If it is the first agent in the list, the second, or if there is a need to create a third
  defp get_social_media_agent(length_first_agent, length_second_agent, average_length_update, _)
       when length_first_agent + length_second_agent / 2 >= average_length_update,
       do: :create

  defp get_social_media_agent(length_first_agent, _, _, %{max_agent_size: max_agent_size})
       when length_first_agent >= max_agent_size do
    :put_second
  end

  defp get_social_media_agent(_, _, _, _) do
    :put_first
  end

  # TODO : update the new_agent to match others agent from which_child
  defp create_new_storage_agent(first_agent, second_agent, social_media, state) do
    new_agent =
      create_agent_spec(first_agent, second_agent, social_media, state)
      |> create_new_agent()

    new_agent_list = List.insert_at(state.agent, 1, new_agent)
    %{state | agents: new_agent_list}
  end

  defp create_agent_spec(first_agent, second_agent, social_media, state) do
    social_medias = merge_social_medias(first_agent, second_agent, social_media, state)
    thread_number = Supervisor.count_children(:social_media_storage_distributor)

    %{
      id: {Storage, thread_number},
      start: {Storage, :start_link, [[social_medias]]}
    }
  end

  defp merge_social_medias(first_agent, second_agent, social_media, state) do
    first_part = Storage.split(first_agent, state.min_agent_size)
    second_part = Storage.split(second_agent, state.min_agent_size)

    first_part ++ second_part ++ [social_media]
  end

  defp create_new_agent(child_spec) do
    {:ok, new_pid} = Supervisor.start_child(:social_media_storage_distributor, child_spec)
    {:new_id, new_pid, :worker, Storage}
  end
end
