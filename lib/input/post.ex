defmodule Zamrazac.Input.Post do
  alias Zamrazac.Util
  alias Zamrazac.Input.Metadata

  defstruct metadata: nil, html: nil

  @doc """
  Parses a post into the metadata, body html, and post path.
  """
  def parse_post(post_path) do
    {:ok, contents} = File.read(post_path)
    ["", raw_metadata_text, raw_post_text] = String.split(contents, "---\n", parts: 3)
    post_basename = Path.basename(post_path, ".md")
    post_html_filename = "#{post_basename}.html"

    parsed_metadata =
      parse_metadata(raw_metadata_text) ++
        [
          filename: post_html_filename,
          basename: post_basename,
          slug: "#{Util.get_blog_posts_root()}#{URI.encode(post_basename)}.html"
        ]
        |> Enum.into( %{} )

    metadata = Map.merge(%Zamrazac.Input.Metadata{}, parsed_metadata)

    {:ok, post_html, []} = Earmark.as_html(raw_post_text)

    patched_html = patchup_images(metadata, post_html)
    %__MODULE__{metadata: metadata, html: patched_html}
  end

  @doc """
  Given a zamrazac-style post metadata string parses it out to a keyword list.
  """
  def parse_metadata(raw_metadata_string) do
    raw_metadata_string
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.map(fn [key, val] ->
      clean_key = String.trim(key) |> String.downcase()

      case clean_key do
        "tags" ->
          tags = val
                |> String.split(",")
                |> Enum.map( fn(tag) ->
                  tag
                  |> String.trim()
                  |> String.downcase()
                end)
                |> Enum.reject( &(&1 == "") )
          {String.to_atom(key), tags}

        "date" ->
          {:ok, datetime, _} = DateTime.from_iso8601(String.trim(val))
          {String.to_atom(key), datetime}

        "series" ->
          {String.to_atom(key), String.trim(val)}

        _ ->
          {String.to_atom(key), String.trim(val)}
      end
    end)
  end

  @doc """
  Given post metadata and markup, sets up image directory for the output and runs the routines that do image patchup.
  """
  def patchup_images(%Metadata{} = metadata, post_html) do
    {:ok, dom} = Floki.parse_fragment(post_html)

    image_storage_path =
      Path.join(Zamrazac.Util.get_blog_output_image_directory(), metadata.basename)

    System.cmd("mkdir", ["-p", image_storage_path])
    patched_dom = Zamrazac.FlokiUtil.walk_dom(dom, image_storage_path)
    Floki.raw_html(patched_dom)
  end
end
