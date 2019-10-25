defmodule AdvancedAggregator.Api.MockTest do
  @moduledoc """
  MockTest is a simple module which as for purpose to replicate an API call.
  """
  @behaviour AdvancedAggregator.Api.ApiBehaviour

  alias HTTPoison.Response
  alias AdvancedAggregatorTest.Support.GenSocialMedias

  @token System.get_env("TEST_KEY", "Default_value")
  @header [Authorization: "Bearer #{@token}", Accept: "Application/json; Charset=utf-8"]
  @base_url "https://localhost:4100/api/1.0"

  def get_data(social_media, key \\ nil) do
    env = Mix.env()

    social_media.name
    |> generate_url(key)
    |> get_posts(env)
  end

  defp generate_url(name, nil), do: "#{@base_url}/get_posts.json?name=#{name}"

  defp generate_url(name, key),
    do: "#{@base_url}/get_posts.json?name=#{name}&since_id=#{key}"

  defp get_posts(url, :test) do
    with {:ok, body} <- GenSocialMedias.gen_json_response(url),
         {:ok, data} <- Poison.decode(body) do
      data
    else
      err -> err
    end
  end

  defp get_posts(url, _) do
    with {:ok, %Response{body: body}} <- HTTPoison.get(url, @header),
         {:ok, data} <- Poison.decode(body) do
      data
    else
      err -> err
    end
  end

  def serialize_results({:error, _} = error), do: error
  def serialize_results([]), do: {:empty, []}
  def serialize_results(results), do: {:ok, Enum.map(results, &adapt_result/1)}

  defp adapt_result(result) do
    %{
      type: "text",
      id: result["id_str"],
      cdate: result["created_at"],
      message: result["text"],
      link: result["link"],
      origin: "test",
      url: "https://localhost:4100/#{result["page"]["id"]}/status/#{result["id_str"]}"
    }
  end
end
