defmodule Zamrazac.Activities.GeneratePosts do
  @doc """
  Function to convert blog posts from a directory.

  Conversion steps are:
  1. Walk the directory and collect the blog posts.
  2. For each blog post,
    2a. Pull out post metadata, remainder goes to 2b
    2b. Convert post from markdown into HTML
    2c. Walk HTML and collect image tags
    2d. For each image tag,
      2di. Download image into blog image directory for post
      2dii. Convert image to dithered 8x8 grayscale, keep original.
      2diii. Read converted image back as data URI
      2div. Replace img tag source with data URI
      2dv. Wrap image tag in anchor tag referencing stored full image.
      2dvi. Add comment for original source of image.
  3. Assemble index/archive view for posts from metadata.
  """
  def generate(posts_directory) do
    post_paths = get_post_paths(posts_directory)
    Enum.map(post_paths, &generate_post/1)
  end

  def get_post_paths(posts_directory) do
    {:ok, files} = File.ls(posts_directory)
    Enum.filter(files, fn (filename) -> String.ends_with?(filename, ".md") end)
    |> Enum.map( fn (filename) -> Path.join(posts_directory, filename) end)
  end

  def generate_post(post_path) do
    {:ok, contents} = File.read(post_path)
    ["", raw_metadata_text, raw_post_text] = String.split(contents, "---\n", parts: 3)
    metadata = parse_metadata(raw_metadata_text)

    IO.inspect [metadata, raw_post_text]
  end

  def parse_metadata(raw_metadata_string) do
    metadata_string = raw_metadata_string |> String.trim()
    metadata_string
    |> String.split("\n", trim: true)
    |> Enum.map( &(String.split(&1,":", parts: 2)) )
    |> Enum.map( fn([key, val]) ->
      clean_key = String.trim(key)
      case clean_key do
        "tags" ->
          {String.to_atom(key), String.split(val) |> Enum.map(&String.downcase/1)}
        "date" ->
          {:ok, datetime, _} = DateTime.from_iso8601(String.trim(val))
          {String.to_atom(key), datetime}
        _ ->
          {String.to_atom(key), String.trim(val)}
      end

    end)
  end
end
