defmodule Mix.Tasks.Zamrazac.Create do
  @moduledoc """
  Creates a new blog post.

  Actions supported:

  - Create new blog post

  Environment variables for doing this:

  * `BLOG_DIRECTORY` is a string for where to store or read blogposts.
  """
  use Mix.Task

  @shortdoc "Create a new post with a given title."
  def run([postname]) when is_binary(postname) do
    Zamrazac.Activities.CreatePost.create(postname, "")
  end
end
