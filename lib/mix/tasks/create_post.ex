defmodule Mix.Tasks.Zamrazac.Create do
  @moduledoc """
  Creates a new blog post.

  Actions supported:

  - Create new blog post

  Environment variables for doing this:

  * `BLOG_DIRECTORY` is a string for where to store or read blogposts.
  * `BLOG_AUTHOR` is a string for the name of the author on the post.
  """
  use Mix.Task
  alias Zamrazac.Util

  @shortdoc "Create a new post with a given title."
  def run([postname]) when is_binary(postname) do
    Zamrazac.Activities.CreatePost.create(postname, Util.get_blog_directory())
  end
end
