defmodule AdvancedAggregatorTest.Support.GenSocialMedias do
  @moduledoc """
  The purpose of GenSocialMedias is to create a random list of social media objects to tests the behavior of the aggregator
  """

  @doc """
  `gen_social_medias/0` allows a controlled test environment, to explicitly know the number of différents elements.
  """
  def gen_social_medias() do
    limit = Application.fetch_env!(:advanced_aggregator, :max_test_entities)
    gen_social_medias(1, limit)
  end

  @doc """
  `gen_random_social_medias/0` allows a more real life situation. It should be used on a special environment
  """
  def gen_random_social_medias() do
    min_element_number = Application.fetch_env!(:advanced_aggregator, :min_test_entities)
    max_element_number = Application.fetch_env!(:advanced_aggregator, :max_test_entities)
    limit = Enum.random(min_element_number..max_element_number)

    gen_social_medias(1, limit)
  end

  defp gen_social_medias(iteration, limit, stash \\ [])
  defp gen_social_medias(iteration, limit, stash) when iteration == limit, do: stash

  defp gen_social_medias(iteration, limit, stash) do
    new_stash =
      stash ++
        [
          %{
            id: iteration,
            name: "toto#{iteration}",
            origin: :test,
            url: "http://test.com/toto#{iteration}"
          }
        ]

    gen_social_medias(iteration + 1, limit, new_stash)
  end

  @doc """
  `gen_json_response/1` allow us to test the result of an API whithout calling the API.
  """
  def gen_json_response(url) when is_bitstring(url) do
    limit = Enum.random(-2..3)
    gen_json_response(limit, url)
  end

  defp gen_json_response(max, url)
  defp gen_json_response(-2, _), do: {:error, "key"}
  defp gen_json_response(-1, _), do: {:error, "some error"}

  defp gen_json_response(max, url, stash \\ [])

  defp gen_json_response(0, _, stash) do
    encoded_data = Poison.encode!(stash)
    {:ok, encoded_data}
  end

  defp gen_json_response(max, url, stash) do
    data = gen_response(max, url)
    new_stash = stash ++ data
    gen_json_response(max - 1, url, new_stash)
  end

  @doc """

  """
  def gen_response(max, url) do
    [
      %{
        "id_str" => "id_string",
        "created_at" => "2019-10-25",
        "text" => "this is some message",
        "link" => url,
        "page" => %{"id" => max}
      }
    ]
  end
end
