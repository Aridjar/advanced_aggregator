defmodule AdvancedAggregator.MockTestTest do
  use ExUnit.Case, async: true

  alias AdvancedAggregator.Api.MockTest
  alias AdvancedAggregatorTest.Support.GenSocialMedias

  test "get data from test API" do
    possibilities = gen_possibilities()

    for i <- 0..20, i > 0 do
      responce = MockTest.get_data(%{name: "test_api_test"})
      assert Enum.member?(possibilities, responce)
    end

    for i <- 0..20, i > 0 do
      responce = MockTest.get_data(%{name: "test_api_test"}, "some_key")
      assert Enum.member?(possibilities, responce)
    end
  end

  describe "serialize results from test API" do
    test "with error" do
      assert MockTest.serialize_results({:error, "some error"}) == {:error, "some error"}
      assert MockTest.serialize_results({:error, "key"}) == {:error, "key"}
    end

    test "empty result" do
      assert MockTest.serialize_results([]) == {:empty, []}
    end

    test "one element" do
      url = "https://localhost:4100/api/1.0/get_posts.json?name=test_api_test"
      one_element = GenSocialMedias.gen_response(1, url)
      assert {:ok, [%{id: _, type: "text"}]} = MockTest.serialize_results(one_element)
    end
  end

  #########################
  ### Private functions ###
  #########################

  defp gen_possibilities() do
    short_url = "https://localhost:4100/api/1.0/get_posts.json?name=test_api_test"
    url = "https://localhost:4100/api/1.0/get_posts.json?name=test_api_test&since_id=some_key"

    [
      {:error, "key"},
      {:error, "some error"},
      []
    ] ++ gen_response(short_url) ++ gen_response(url)
  end

  defp gen_response(url) do
    one_element = GenSocialMedias.gen_response(1, url)
    two_elements = GenSocialMedias.gen_response(2, url) ++ one_element
    three_elements = GenSocialMedias.gen_response(3, url) ++ two_elements

    [one_element, two_elements, three_elements]
  end
end
