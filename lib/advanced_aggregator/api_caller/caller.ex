defmodule AdvancedAggregator.ApiCaller.Caller do
  @moduledoc """
  The caller module is a host for the task created in dynamic_handler
  It only have two functions.

  The first and most important one is `get_post_from_social_media/1`, which take a social_media as argument
  The guard allow to execut specific task depending of the social media

  # TODO : look if there is a way to make it generic. While it is not generic, follow the next line:
  There should be one `get_post_from_social_media/1` per social_media, to avoid confusion and use the correct API

  the last function, `send_to_channel` will handle any errors happening during the process.
  If there is none, it will send the data to the webhook application through channel, so anyone connected will get the new posts.
  """
  use Task
  alias AdvancedAggregator.Api.MockTest

  # TODO : uncomment

  def get_post_from_social_media(%{origin: origin} = social_media)
      when origin == :test do
    # key = Redis.get_last_call_social_media(origin, id)
    key = nil

    MockTest.get_data(social_media, key)
    |> MockTest.serialize_results()
    # |> Redis.save_posts()
    |> send_to_channel(social_media)
  end

  def get_post_from_social_media(%{origin: origin} = _social_media)
      when origin == :twitter do
    # key = Redis.get_social_media_last_call(origin, id)

    # Twitter.get_data(social_media, key)
    # |> Twitter.sort_data()
    # |> Redis.save_posts()
    # |> do_send_to_channel(social_media)
    IO.puts("twitter")
  end

  defp send_to_channel({:error, reason}, %{id: _id, origin: _origin}) do
    # if length(posts.posts) > 0 do
    #   SenderWeb.Endpoint.broadcast!("page: #{social_media_id}", "updated", %{
    #     posts: posts.posts
    #   })
    # end
    "error: #{reason}"
  end

  defp send_to_channel({:empty, _}, %{id: _id, origin: _origin}) do
    # if length(posts.posts) > 0 do
    #   SenderWeb.Endpoint.broadcast!("page: #{social_media_id}", "updated", %{
    #     posts: posts.posts
    #   })
    # end
    "no new posts"
  end

  defp send_to_channel({:ok, _post}, %{id: _id, origin: _origin}) do
    # if length(posts.posts) > 0 do
    #   SenderWeb.Endpoint.broadcast!("page: #{social_media_id}", "updated", %{
    #     posts: posts.posts
    #   })
    # end
    "send to webhooks"
  end
end
