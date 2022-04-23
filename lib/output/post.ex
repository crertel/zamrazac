defmodule Zamrazac.Output.Post do
  alias Zamrazac.Util
  alias Zamrazac.Input.Metadata
  use Phoenix.HTML

  @doc """
  Renders the actual post to an HTML file.
  """
  def write_post_file(path, %Metadata{} = metadata, post_html, series_information) do
    {:safe, post_content} =
      EEx.eval_string(
        post_template(),
        [
          blog_title: Util.get_blog_title(),
          post_date: metadata.date |> DateTime.to_iso8601() |> String.slice(0..9),
          post_title: metadata.title,
          post_author: metadata.author,
          post_tags: metadata.tags,
          post_metadata: inspect(metadata, pretty: true),
          post_body: post_html,
          feed_url: Util.get_feed_url(),
          styles: Util.get_styles(),
          next_post_title: metadata.next_post_title || "",
          next_post_path: metadata.next_post_path || "",
          prev_post_title: metadata.prev_post_title || "",
          prev_post_path: metadata.prev_post_path || "",
          post_series: metadata.series,
          series_information:
            series_information
            |> Enum.sort(fn a, b ->
              # blech, fix this when I'm not tired
              Date.compare(a.date, b.date) != :lt
            end)
        ],
        engine: Phoenix.HTML.Engine
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

        <%= Phoenix.HTML.raw styles || "" %>
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
        <%= Phoenix.HTML.raw post_body %>

        <%= if length(post_tags) > 0 do %>
          <hr>
          <div>
          <b>Tags:</b>
          <%= for tag <- post_tags do %>
            <a href="/tag_index-<%= Zamrazac.Util.slugify_tag(tag)%>.html">
            <%= tag %>
            </a>
          <% end %>
          </div>
        <% end %>
        <%= if length(series_information) > 0 do %>
          <hr>
          <div>
            <h3>Other <%= post_series %> posts:</h3>
            <ul>
            <%= for post_in_series <- series_information do %>
              <li>
                <a href="../posts/<%= post_in_series.filename %>">
                <%= post_in_series.date %> - <%= post_in_series.title %>
                </a>
              </li>
            <% end %>
            </ul>
          </div>
        <% end %>

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
