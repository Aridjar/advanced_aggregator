defmodule AdvancedAggregator.SocialMediaStorage.StorageTest do
  use ExUnit.Case, async: true

  alias AdvancedAggregator.SocialMediaStorage.Storage

  setup do
    {:ok, storage} = Storage.start_link({:social_media, %{}})
    %{storage: storage}
  end

  test "stores a value by key and retrieves this value", %{storage: storage} do
    assert Storage.get(storage, 3) == nil
    assert Storage.put(storage, 3, %{id: 3}) == :ok
    assert Storage.get(storage, 3) == %{id: 3}
  end

  test "stores multiple values, retrieves each and update the agent", %{storage: storage} do
    assert Storage.all(storage) == %{}

    Storage.put(storage, 1, %{id: 1})
    Storage.put(storage, 2, %{id: 2})
    assert Storage.all(storage) == %{1 => %{id: 1}, 2 => %{id: 2}}

    assert Storage.drop(storage, [2]) == :ok
    assert Storage.all(storage) == %{1 => %{id: 1}}
  end

  test "count values in agent", %{storage: storage} do
    assert Storage.count(storage) == 0

    Storage.put(storage, 1, %{id: 1})
    assert Storage.count(storage) == 1
  end

  test "split agent data", %{storage: storage} do
    Storage.put(storage, 1, %{id: 1})
    Storage.put(storage, 2, %{id: 2})

    assert Storage.split(storage, 1) == %{2 => %{id: 2}}
    assert Storage.all(storage) == %{1 => %{id: 1}}
  end
end
