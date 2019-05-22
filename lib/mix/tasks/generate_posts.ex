defmodule Mix.Tasks.Zamrazac.Generate do
  @moduledoc """
  Generates posts from a blog directory.

  Actions supported:

  - Generates the HTML and packaged images from a blog directory.

  Environment variables for doing this:

  * `BLOG_DIRECTORY` is a string for where to store or read blogposts.
  """
  use Mix.Task

  @shortdoc "Plows through and converts posts to HTML."
  def run([postname]) when is_binary(postname) do
    blog_directory = System.get_env("BLOG_DIRECTORY")
    Zamrazac.Activities.GeneratePosts.generate("")
  end
end
