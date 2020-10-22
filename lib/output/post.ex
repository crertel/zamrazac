defmodule Zamrazac.Output.Post do
  alias Zamrazac.Util

  @doc """
  Renders the actual post to an HTML file.
  """
  def write_post_file(path, metadata, post_html) do
    post_content =
      EEx.eval_string(
        post_template(),
        [
          blog_title: Util.get_blog_title(),
          post_date: metadata[:date] |> DateTime.to_iso8601() |> String.slice(0..9),
          post_title: metadata[:title],
          post_author: metadata[:author],
          post_metadata: inspect(metadata, pretty: true),
          post_body: EExHTML.raw(post_html),
          feed_url: Util.get_feed_url(),
          styles: EExHTML.raw(Util.get_styles()),
          next_post_title: metadata[:next_post_title] || "",
          next_post_path: metadata[:next_post_path] || "",
          prev_post_title: metadata[:prev_post_title] || "",
          prev_post_path: metadata[:prev_post_path] || ""
        ],
        engine: EExHTML.Engine
      )

    :ok = File.write(path, "#{post_content}")
  end

  def post_template() do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
        <meta http-equiv="Pragma" content="no-cache" />
        <meta http-equiv="Expires" content="0" />
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title><%= post_title %></title>
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
      <!--
      <%= post_metadata %>
      -->
        <div class="post-main">
        <small>
          <div class="post-nav-container">
            <%= if next_post_path != "" do %>
            <a href="<%= next_post_path %>" class="post-nav-link"> << <%= next_post_title %> </a>
            <% end %>
            <a href="../index.html" class="post-nav-link">Back to index...</a>
            <%= if prev_post_path != "" do %>
              <a href="<%= prev_post_path %>" class="post-nav-link"> <%= prev_post_title %> >> </a>
            <% end %>
          </div>
        </small>
        <hr>

        <h1><%= blog_title %></h1>
        <h2><%=post_date %> -- <%= post_title %></h2>
        <h3><%= post_author %></h3>
        <%= post_body %>

        <hr>
        <small>
          <div class="post-nav-container">
            <%= if next_post_path != "" do %>
            <a href="<%= next_post_path %>" class="post-nav-link"> << <%= next_post_title %> </a>
            <% end %>
            <a href="../index.html" class="post-nav-link">Back to index...</a>
            <%= if prev_post_path != "" do %>
              <a href="<%= prev_post_path %>" class="post-nav-link"> <%= prev_post_title %> >> </a>
            <% end %>
          </div>
        </small>
        </div>
      </body>
    </html>
    """
  end
end
