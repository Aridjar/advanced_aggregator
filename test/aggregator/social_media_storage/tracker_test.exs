defmodule AdvancedAggregator.SocialMediaStorage.StorageTrackerTest do
  use ExUnit.Case, async: true

  describe "test initialization" do
    setup do
      tracker = start_supervised!(AdvancedAggregator.SocialMediaStorage.StorageTracker)
      %{tracker: tracker}
    end

    test "cast :complete_init", %{tracker: tracker} do
      max_agent_size = Application.get_env(:advanced_aggregator, :max_social_media)
      min_agent_size = Application.get_env(:advanced_aggregator, :min_social_media)

      assert :sys.get_state(tracker) == %{
               agents: [],
               init_completed: false,
               max_agent: 0,
               max_agent_size: max_agent_size,
               min_agent_size: min_agent_size
             }

      GenServer.cast(tracker, :complete_init)

      assert %{
               init_completed: true,
               max_agent_size: max_agent_size,
               min_agent_size: min_agent_size
             } = :sys.get_state(tracker)
    end
  end

  describe "test handle_call" do
    setup do
      tracker = start_supervised!(AdvancedAggregator.SocialMediaStorage.StorageTracker)

      GenServer.cast(tracker, :complete_init)
      %{tracker: tracker}
    end

    test "get pid", %{tracker: tracker} do
      pid = GenServer.call(tracker, :get_agent)

      assert is_pid(pid)
      assert GenServer.call(tracker, {:get_agent, 0}) == pid
    end

    test "get social medias", %{tracker: tracker} do
      social_medias = GenServer.call(tracker, :get_social_medias)

      assert is_map(social_medias)
      assert %{id: 1} = social_medias[1]
      assert GenServer.call(tracker, {:get_social_medias, 0}) == social_medias
    end

    test "pop agent", %{tracker: tracker} do
      pid_first_agent = GenServer.call(tracker, :get_agent)
      pid_second_agent = GenServer.call(tracker, {:get_agent, 1})

      assert GenServer.call(tracker, :pop_agent) == pid_first_agent
      assert GenServer.call(tracker, :pop_agent) == pid_second_agent
    end
  end

  # describe "test handle_cast" do
  #   setup do
  #     tracker = start_supervised!(AdvancedAggregator.SocialMediaStorage.StorageTracker)

  #     GenServer.cast(tracker, :complete_init)
  #     %{tracker: tracker}
  #   end

  #   test "add_new_social_media"
  # end
end
