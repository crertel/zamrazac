defmodule Zamrazac.Activities.CreatePost do

  @doc """
  Function that, given a post name and a posts directory, creates a post file and opens an editor.

  1. Convert postname into slug (prefix RFC-3339 UTC date, downcase, snake-case)
  2. Create a file with filename of slug from (1) in the blog directory.
  3. Write stub metadata (normal postname, creation time).
  4. Open editor pointing at (2).
  """
  def create(postname, posts_directory) do
    IO.inspect(postname, label: "CREATE" )
    {:ok, myfile} = File.open(Path.join(posts_directory, postname) , [:write ])
    IO.inspect(myfile)
    IO.binwrite(myfile,
    blog_metadata(DateTime.utc_now() |> DateTime.to_iso8601(),
      "Chris 'The Amazing' Ertel",
      postname
    ))
    IO.puts("wrote to file")
    File.close(myfile)
  end

  def blog_metadata(today, author, title) do
    """
    ---
    title: #{title}
    author: #{author}
    date: #{today}
    ---
    """
  end
end
