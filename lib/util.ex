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
  Get the default blog directory, which is typically off of the zamrazac directory.
  """
  def get_default_blog_directory() do
    __ENV__.file
    |> Path.dirname()
    |> Path.join( "../blog")
    |> Path.expand()
  end

  @doc """
  Gets the image directory for the blog, using either the default or environment-defined directory.
  """
  def get_blog_image_directory(), do: Path.join(get_blog_directory(), "images")

end
