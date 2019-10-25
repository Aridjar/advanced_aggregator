defmodule AdvancedAggregator.CallerTest do
  use ExUnit.Case, async: true

  alias AdvancedAggregator.ApiCaller.Caller

  test "test get post from social media" do
    possibilities = [
      "send to webhooks",
      "error: key",
      "error: some error",
      "no new posts"
    ]

    for i <- 0..10, i > 0 do
      responce = Caller.get_post_from_social_media(%{origin: :test, name: "test", id: 1})
      assert Enum.member?(possibilities, responce)
    end
  end
end
