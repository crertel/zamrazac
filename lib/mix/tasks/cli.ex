defmodule Mix.Tasks.Zamrazac do
  @moduledoc """
  Tool to create new blogposts and to generate a whole blog.

  Actions supported:

  - Create new blog post
  - Process directory of posts

  Environment variables for doing this:

  * `BLOG_DIRECTORY` is a string for where to store or read blogposts.
  """
  use Mix.Task

  def run(_) do
    IO.puts("""
    usage:

    """)
  end
end
