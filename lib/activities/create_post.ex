defmodule Zamrazac.Activities.CreatePost do
  @doc """
  Function that, given a post name and a posts directory, creates a post file and opens an editor.

  1. Convert postname into slug (prefix RFC-3339 UTC date, downcase, snake-case)
  2. Create a file with filename of slug from (1) in the blog directory.
  3. Write stub metadata (normal postname, creation time).
  4. Open editor pointing at (2).
  """
  def create(postname, posts_directory) do
    System.cmd("mkdir", ["-p", posts_directory])

    slug =
      postname
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/[[:^alnum:]]/, "_")

    date_string = DateTime.utc_now() |> DateTime.to_iso8601()
    filename = Path.join(posts_directory, "#{date_string}_#{slug}.md")
    {:ok, myfile} = File.open(filename, [:write])

    IO.binwrite(
      myfile,
      blog_metadata(
        date_string,
        System.get_env("BLOG_AUTHOR") || "<anonymous>",
        postname
      )
    )

    File.close(myfile)
    Execv.exec([System.find_executable("vim"), "+", filename])
  end

  def blog_metadata(today, author, title) do
    """
    ---
    title: #{title}
    author: #{author}
    date: #{today}
    tags:
    ---


    """
  end
end
