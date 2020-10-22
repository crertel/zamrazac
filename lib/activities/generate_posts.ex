defmodule Zamrazac.Activities.GeneratePosts do
  @moduledoc """
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

  alias Zamrazac.Util
  alias Zamrazac.Output
  alias Zamrazac.Input

  @doc """
  Function to crawl a posts directory and turn it into html, generate an index, and generate supporting image files.
  """
  def generate(posts_directory) do
    post_paths = get_post_paths(posts_directory)
    System.cmd("mkdir", ["-p", Util.get_output_directory()])
    System.cmd("mkdir", ["-p", Util.get_blog_output_image_directory()])
    System.cmd("mkdir", ["-p", Util.get_blog_output_post_directory()])
    posts = Enum.map(post_paths, &Input.Post.parse_post/1)

    sorted_posts =
      Enum.sort_by(posts, fn %Input.Post{metadata: a_metadata} ->
        a_metadata[:date] |> DateTime.to_iso8601()
      end)
      |> Enum.reverse()

    post_metadatas = for %Input.Post{metadata: metadata} <- sorted_posts, into: [], do: metadata
    # agg_post_data = aggregate_metadata(post_metadatas)

    chunked_posts = Enum.chunk_every([nil] ++ sorted_posts ++ [nil], 3, 1, :discard)
    Enum.map(chunked_posts, &write_post/1)

    Output.Index.generate_post_index(post_metadatas)
    Output.RSS.generate_rss_feed(post_metadatas)
  end

  def aggregate_metadata(metadatas) do
    Enum.reduce(
      metadatas,
      %{series: %{}},
      fn post_metadata, acc ->
        acc
      end
    )
  end

  def write_post([
        prev_post,
        %Input.Post{metadata: metadata, html: post_body_html} = post,
        next_post
      ]) do
    post_html_path = Path.join(Util.get_blog_output_post_directory(), metadata[:filename])
    IO.puts("Writing post #{metadata[:title]} to #{post_html_path}")

    patched_metadata =
      Keyword.merge(metadata,
        next_post_path:
          if next_post != nil do
            "../posts/#{next_post.metadata[:filename]}"
          else
            ""
          end,
        next_post_title:
          if next_post != nil do
            "../posts/#{next_post.metadata[:title]}"
          else
            ""
          end,
        prev_post_path:
          if prev_post != nil do
            "../posts/#{prev_post.metadata[:filename]}"
          else
            ""
          end,
        prev_post_title:
          if prev_post != nil do
            "../posts/#{prev_post.metadata[:title]}"
          else
            ""
          end
      )

    Output.Post.write_post_file(post_html_path, patched_metadata, post_body_html)
  end

  @doc """
  Crawls the posts directory and extracts the markdown files that look relevant.
  """
  def get_post_paths(posts_directory) do
    {:ok, files} = File.ls(posts_directory)

    Enum.filter(files, fn filename -> String.ends_with?(filename, ".md") end)
    |> Enum.map(fn filename -> Path.join(posts_directory, filename) end)
  end
end
