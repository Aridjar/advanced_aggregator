defmodule AdvancedAggregator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: AdvancedAggregator.Worker.start_link(arg)
      # {AdvancedAggregator.Worker, arg}

      # {AdvancedAggregator.ApiCaller.DynamicHandler, []},
      {AdvancedAggregator.SocialMediaStorage.Distributor, []},
      {AdvancedAggregator.SocialMediaStorage.StorageTracker, []},
      {AdvancedAggregator.Timer, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AdvancedAggregator.Supervisor]

    {:ok, pid} = Supervisor.start_link(children, opts)

    GenServer.cast(:social_media_storage_tracker, :complete_init)
    GenServer.cast(:aggregator_timer, :complete_init)

    {:ok, pid}
  end
end
