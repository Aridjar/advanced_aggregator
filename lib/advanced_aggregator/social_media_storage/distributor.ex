defmodule AdvancedAggregator.SocialMediaStorage.Distributor do
  @moduledoc """
  The distributor manage the storages agents under it.
  It as for purpose to allocate created social_medias to an element in the agent.
  To do so, it get all social_media from the database, and some configuration,
  and create agents. While creating agents, it assign them a list of social_medias and a number.
  """

  use Supervisor

  alias AdvancedAggregator.SocialMediaStorage.Storage
  alias AdvancedAggregatorTest.Support.GenSocialMedias

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: :social_media_storage_distributor)
  end

  ##################
  ### Init phase ###
  ##################

  @impl true
  def init(_) do
    elements_per_agent = get_elements_per_agent()

    Mix.env()
    |> get_social_medias()
    |> generate_children(elements_per_agent)
    |> Supervisor.init(strategy: :one_for_one)
  end

  # return the middle between
  defp get_elements_per_agent() do
    max_social_media = Application.fetch_env!(:advanced_aggregator, :max_social_media)

    Application.fetch_env!(:advanced_aggregator, :min_social_media)
    |> Kernel.+(max_social_media)
    |> Kernel.div(2)
  end

  defp get_social_medias(:test = _),
    do: GenSocialMedias.gen_social_medias()

  defp get_social_medias(:production_test = _),
    do: GenSocialMedias.gen_random_social_medias()

  # The following function should call SocialMedias.list_social_medias(:no_preload).
  # Because SocialMedias is supposed to be in the Database app (of an umbrella app), we can't call it
  defp get_social_medias(_), do: nil

  defp generate_children(social_medias, element_per_agent, agent_number \\ 0, stash \\ [])
  defp generate_children(social_medias, elements_per_agent, agent_number, stash)
  defp generate_children([], _, _, stash), do: stash

  defp generate_children(social_medias, elements_per_agent, agent_number, stash) do
    # get the N first elements of the social medias list
    {head, tail} =
      social_medias
      |> split_social_medias(elements_per_agent)

    new_stash =
      head
      |> Map.new(fn social_media -> {social_media.id, social_media} end)
      |> generate_new_stash(agent_number, stash)

    generate_children(tail, elements_per_agent, agent_number + 1, new_stash)
  end

  defp split_social_medias(social_medias, elements_per_agent) do
    enhanced_agent_remaining =
      social_medias
      |> count_enhanced_agent_remaining(elements_per_agent)

    if enhanced_agent_remaining > 0 do
      Enum.split(social_medias, elements_per_agent + 1)
    else
      Enum.split(social_medias, elements_per_agent)
    end
  end

  defp count_enhanced_agent_remaining(social_medias, elements_per_agent) do
    social_medias |> length() |> rem(elements_per_agent)
  end

  defp generate_new_stash(social_medias, agent_number, stash) do
    stash ++
      [
        %{
          id: {Storage, "storage_#{agent_number}"},
          start: {Storage, :start_link, [social_media: social_medias]}
        }
      ]
  end

  #########################
  ### End of init phase ###
  #########################
end
