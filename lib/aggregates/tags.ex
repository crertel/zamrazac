defmodule Zamrazac.Aggregate.Tags do
  alias Zamrazac.Input.Metadata

  @moduledoc """
  Module for handling aggregates of post series.
  """

  @doc """
  Given a collection of metadata structs, returns a map from tag to a list of slugs that it applies to.
  """
  def run(metadatas) when is_list(metadatas) do
    all_tags_table = :ets.new(:zamrazac_aggregate_tags, [:set, :named_table])
    post_to_tags_table = :ets.new(:zamrazac_aggregate_post_tags, [:bag, :named_table])

    Enum.each(metadatas, fn %Metadata{} = metadata ->
      for tag <- metadata.tags do
        :ets.insert(all_tags_table, {tag})
        :ets.insert(post_to_tags_table, {tag, metadata.slug})
      end
    end)

    registered_tags = :ets.tab2list(all_tags_table) |> Enum.map(&elem(&1, 0))

    Enum.reduce(registered_tags, %{}, fn tag, mappings ->
      existing_posts_for_tag = Map.get(mappings, tag, [])
      stored_posts_for_tag = :ets.lookup(post_to_tags_table, tag) |> Enum.map(&elem(&1, 1))
      updated_posts_for_tag = stored_posts_for_tag ++ existing_posts_for_tag
      Map.put(mappings, tag, updated_posts_for_tag)
    end)
  end
end
