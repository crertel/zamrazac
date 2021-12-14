defmodule Zamrazac.Output.Index do
  alias Zamrazac.Util

  @doc """
  Function that creates an index file given a pile of post metadata objects.
  """
  def generate_post_index(post_metadatas) do
    index_path = Path.join(Util.get_output_directory(), "index.html")
    IO.puts("Writing index to #{index_path}")

    index_content =
      EEx.eval_string(
        index_template(),
        [
          posts: post_metadatas,
          blog_title: Util.get_blog_title(),
          feed_url: Util.get_feed_url(),
          styles: EExHTML.raw(Util.get_styles())
        ],
        engine: EExHTML.Engine
      )

    :ok = File.write(index_path, "#{index_content}")
  end

  def index_template() do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title><%= blog_title %></title>
        <style>
        .post-main {
          max-width: 960px;
          margin: auto;
        }

        <%= styles || "" %>
        </style>
        <link rel="alternate" type="application/rss+xml" href="<%= feed_url %>" title="<%= blog_title %>">
      </head>
      <body>
        <div class="post-main">
          <h1><%= blog_title %> Posts</h1>
          <ul>
            <%= for post <- posts do %>
              <li>
                <%= post.date |> DateTime.to_iso8601() |> String.slice( 0..9)%>
                <a href="../posts/<%= post.filename%>"> <%= post.title %> </a>
              </li>
            <% end %>
          </ul>
          <div>
          <a href="./feed.xml">RSS feed</a>
          </div>
        </div>
      </body>
    </html>
    """
  end
end
