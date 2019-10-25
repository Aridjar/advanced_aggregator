defmodule AdvancedAggregator.TimerTest do
  use ExUnit.Case, async: true

  describe "test initialization" do
    setup do
      timer = start_supervised!(AdvancedAggregator.Timer)
      %{timer: timer}
    end

    test "cast :complete_init", %{timer: timer} do
      base_timer = Application.fetch_env!(:advanced_aggregator, :timer)

      assert :sys.get_state(timer) == %{
               agent: 0,
               init_completed: false,
               base_timer: base_timer,
               max_agent: 0,
               timer: 0
             }

      GenServer.cast(timer, :complete_init)

      assert %{init_completed: true} = :sys.get_state(timer)
    end
  end

  describe "test handle_cast" do
    setup do
      timer = start_supervised!(AdvancedAggregator.Timer)
      GenServer.cast(timer, :complete_init)
      %{timer: timer}
    end

    test "update max agent", %{timer: timer} do
      state = get_state(timer)

      new_max_agent = state.max_agent + 1
      GenServer.cast(timer, {:update_max_agent, new_max_agent})
      new_timer = div(state.base_timer, new_max_agent)

      state
      |> update_state(%{timer: new_timer, max_agent: new_max_agent})
      |> assert_compare_state(timer)
    end

    test "update base timer", %{timer: timer} do
      state = get_state(timer)

      new_base_timer = state.base_timer + 1
      GenServer.cast(timer, {:update_base_timer, new_base_timer})
      new_timer = div(new_base_timer, state.max_agent)

      state
      |> update_state(%{timer: new_timer, base_timer: new_base_timer})
      |> assert_compare_state(timer)
    end
  end

  # Haven't find a way to do the following thing yet:

  # describe "test schedule_work" do
  #   setup do
  #     timer = start_supervised!(AdvancedAggregator.Timer)
  #     GenServer.cast(timer, :complete_init)
  #     %{timer: timer}
  #   end

  #   # TODO : test one loop of the element
  #   test "monitor handle_info()", %{timer: timer} do
  #     ref = Process.monitor(timer)

  #     state = get_state(timer)
  #     assert_receive {:DOWN, ^ref, :process, timer, {:noproc, _}}, state.timer

  #     state.timer
  #     |> Process.sleep()

  #     state
  #     |> update_state(%{agent: state.agent + 1})
  #   end
  # end

  defp get_state(timer) do
    :sys.get_state(timer)
  end

  defp update_state(state, new_state) do
    state
    |> Map.merge(new_state)
  end

  defp assert_compare_state(state, timer) do
    assert state == get_state(timer)
  end
end
