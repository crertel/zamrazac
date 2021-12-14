defmodule Zamrazac.Aggregate.Series do
  alias Zamrazac.Input.Metadata

  @moduledoc """
  Module for handling aggregates of post series.
  """

  def run(metadatas) when is_list(metadatas) do
    series_map = metadatas
    |> Enum.group_by( fn( %Metadata{series: series})-> series end, fn %Metadata{slug: slug} -> slug end)
    |> Map.drop([nil, ""])

    series_table = :ets.new(:zamrazac_aggregate_series, [:set])
    slug_to_series_table = :ets.new(:zamrazac_aggregate_series, [:set])
    Enum.each(series_map, fn( {series, slugs}) ->
      :ets.insert(series_table, {series, slugs})
      for slug <- slugs do
        :ets.insert(slug_to_series_table, {slug, series})
      end
    end)
    Enum.into( :ets.tab2list(series_table), %{})
  end

end
