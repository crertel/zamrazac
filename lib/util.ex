defmodule Zamrazac.Util do
  @moduledoc """
  Module to hold kitchen-sink functions.
  """

  def get_blog_title() do
    System.get_env("BLOG_TITLE") || "<default blog>"
  end

  def get_blog_description() do
    System.get_env("BLOG_DESCRIPTION") || "<default description>"
  end

  def get_blog_url() do
    System.get_env("BLOG_URL") || "<default blog url>"
  end

  def get_blog_posts_root() do
    System.get_env("BLOG_POSTS_ROOT") || "<default blog posts url>"
  end

  def get_feed_url() do
    "#{get_blog_url()}/feed.xml"
  end


  @doc """
  get_blog_directory will return the directory where blog files are stored.
  First check the value of $BLOG_DIRECTORY in the environment, otherwise default to ./blog
  """
  def get_blog_directory() do
    (System.get_env("BLOG_DIRECTORY") || get_default_blog_directory())
    |> Path.expand()
  end

  @doc """
  get_output_directory will return the directory where blog files are stored.
  First check the value of $OUTPUT_DIRECTORY in the environment, otherwise default to ./blog_output
  """
  def get_output_directory() do
    (System.get_env("OUTPUT_DIRECTORY") || get_default_output_directory())
    |> Path.expand()
  end

  @doc """
  Get the default blog directory, which is typically off of the zamrazac directory.
  """
  def get_default_blog_directory() do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("../blog")
    |> Path.expand()
  end

  @doc """
  Get the default blog output directory, which is typically off of the zamrazac directory.
  """
  def get_default_output_directory() do
    __ENV__.file
    |> Path.dirname()
    |> Path.join("../blog_output")
    |> Path.expand()
  end

  @doc """
  Gets the image directory for the blog output, using either the default or environment-defined directory.
  """
  def get_blog_output_image_directory(), do: Path.join(get_output_directory(), "images")

  @doc """
  Gets the posts directory for the blog output, using either the default or environment-defined directory.
  """
  def get_blog_output_post_directory(), do: Path.join(get_output_directory(), "posts")

  @doc """
  Returns a file as a data-uri.
  """
  def get_file_as_data_uri(absolute_file_path, mimetype) do
    {:ok, file_data} = File.read(absolute_file_path)
    b64_file_data = Base.encode64(file_data)
    "data:#{mimetype};base64,#{b64_file_data}"
  end

  @doc """
  Generates a termporary filename.

  Makes no attempt at uniqueness across runs or against existing filesystem state.
  """
  def get_temp_filename(), do: "#{:erlang.phash2(make_ref())}"

  @doc """
  Makes a SHA-256 hash of a binary and hex encodes it.
  """
  def shahexhash(str), do: Base.encode16(:crypto.hash(:sha256, str))

  @doc """
  Gets the styles from a file, if available.
  """
  def get_styles() do
    styles_path = System.get_env("BLOG_STYLES") |> Path.expand()
    case File.read(styles_path) do
      {:ok, file_data} -> file_data
        _ -> ""
    end
  end


  def slugify_tag(tag) do
    tag
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[[:space]]+/, "_")
    |> String.replace(~r/\?/, "_")
    |> String.replace(~r/#/, "_")
    |> String.replace(~r/\./, "_")
    |> String.replace(~r/\:/, "_")
  end
end
