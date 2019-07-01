defmodule Mix.Tasks.Zamrazac.Generate do
  @moduledoc """
  Generates posts from a blog directory.

  Actions supported:

  - Generates the HTML and packaged images from a blog directory.

  Environment variables for doing this:

  * `BLOG_DIRECTORY` is a string for where to store or read blogposts.
  * `BLOG_TITLE` is the title for the blog.
  * `OUTPUT_DIRECTORY` is a string for where to store the generated html posts
  * `BLOG_URL` is a string of the base URL for the main blog.
  * `BLOG_POSTS_ROOT` is a string of the URL folder to find the posts.
  * `BLOG_DESCRIPTION` is a short string (<200 chars) of what the blog is about.
  * `BLOG_STYLES` is a path to a styles file if available.
  """
  use Mix.Task
  alias Zamrazac.Util

  @shortdoc "Plows through and converts posts to HTML."
  def run(_) do
    blog_directory = System.get_env("BLOG_DIRECTORY") || Util.get_blog_directory()
    Zamrazac.Activities.GeneratePosts.generate(blog_directory)
  end
end
