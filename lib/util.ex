defmodule Zamrazac.Util do
  @moduledoc """
  Module to hold kitchen-sink functions.
  """

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
  Returns a file as a data-uri.
  """
  def get_file_as_data_uri(absolute_file_path, mimetype) do
    {:ok, file_data} = File.read(absolute_file_path)
    b64_file_data = Base.encode64(file_data)
    "data:#{mimetype};base64,#{b64_file_data}"
  end
end
