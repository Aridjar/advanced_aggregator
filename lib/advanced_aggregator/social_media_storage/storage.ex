defmodule AdvancedAggregator.SocialMediaStorage.Storage do
  @moduledoc """
  The storage module is here to store pages. It is an agent, and is under the distributor.
  It also as some function allowing to interact with the list, and directly with one element.

  It should store elements in an map, where the key is the ID of the social_media and the value is the social media itself

  All functions name are the same as the map if they exist.
  Some function, such as `split/2` may need to do more, in purpose to keep the Agent in the correct state.
  Finally, some function, such as `all/1`don't have an equivalent in the Map documentation.
  """

  use Agent

  ############
  ### init ###
  ############

  def start_link(social_medias) do
    Agent.start_link(fn -> elem(social_medias, 1) end)
  end

  #########################################
  ### logic: like the Map documentation ###
  #########################################

  def count(pid), do: Agent.get(pid, &Enum.count(&1))
  def drop(pid, keys), do: Agent.update(pid, &Map.drop(&1, keys))
  def get(pid, key), do: Agent.get(pid, &Map.get(&1, key))
  def keys(pid), do: Agent.get(pid, &Map.keys(&1))
  def put(pid, key, social_media), do: Agent.update(pid, &Map.put(&1, key, social_media))

  ###########################################
  ### logic: not in the Map documentation ###
  ###########################################

  def all(pid, keys), do: Agent.get(pid, &Map.take(&1, keys))

  def all(pid) do
    keys = keys(pid)
    Agent.get(pid, &Map.take(&1, keys))
  end

  ##############################################
  ### logic: different from the Map/Enum doc ###
  ##############################################

  @doc """
  Split takes an agent PID and a count.
  As the Enum function, it return a head and a tail.

  Because split change the state of the enumerable, the agent needs to be updated.
  """
  def split(pid, count) do
    {_, keys} =
      keys(pid)
      |> Enum.split(count)

    tail = all(pid, keys)
    drop(pid, keys)
    tail
  end
end
