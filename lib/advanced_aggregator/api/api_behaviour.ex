defmodule AdvancedAggregator.Api.ApiBehaviour do
  # https://elixirschool.com/en/lessons/advanced/behaviours/

  @callback get_data(social_media :: map, key :: String.t()) :: map
  @callback serialize_results(results :: list | map | tuple) :: tuple
end
