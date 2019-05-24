defmodule Mix.Tasks.Zamrazac.Generate do
  @moduledoc """
  Generates posts from a blog directory.

  Actions supported:

  - Generates the HTML and packaged images from a blog directory.

  Environment variables for doing this:

  * `BLOG_DIRECTORY` is a string for where to store or read blogposts.
  * `BLOG_TITLE` is the title for the blog.
  * `OUTPUT_DIRECTORY` is a string for where to store the generated html posts
  """
  use Mix.Task
  alias Zamrazac.Util

  @shortdoc "Plows through and converts posts to HTML."
  def run(_) do
    blog_directory = System.get_env("BLOG_DIRECTORY") || Util.get_blog_directory()
    Zamrazac.Activities.GeneratePosts.generate(blog_directory)
  end
end
