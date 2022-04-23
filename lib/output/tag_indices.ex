defmodule Zamrazac.Output.TagIndices do
  alias Zamrazac.Util
  use Phoenix.HTML

  @doc """
  Function that creates an index file given a pile of post metadata objects.
  """
  def generate_tag_indices() do
    tag_table = :ets.whereis(:zamrazac_aggregate_tags)
    tag_slug_table = :ets.whereis(:zamrazac_aggregate_post_tags)
    metadata_table = :ets.whereis(:zamrazac_metadata)
    tags = :ets.tab2list(tag_table)

    tag_links =
      for {tag} <- tags do
        tag_slug = Util.slugify_tag(tag)
        tag_index_path = "./tag_index-#{tag_slug}.html"
        {tag, tag_index_path}
      end

    for {tag} <- tags do
      tag_slug = Util.slugify_tag(tag)
      index_path = Path.join(Util.get_output_directory(), "tag_index-#{tag_slug}.html")

      post_slugs = :ets.lookup(tag_slug_table, tag) |> Enum.map(&elem(&1, 1))

      posts =
        for slug <- post_slugs do
          [{_slug, md}] = :ets.lookup(metadata_table, slug)
          md
        end

      {:safe, index_content} =
        EEx.eval_string(
          index_template(),
          [
            tag: tag,
            posts: posts,
            tags: tag_links,
            blog_title: Util.get_blog_title(),
            feed_url: Util.get_feed_url(),
            styles: Util.get_styles()
          ],
          engine: Phoenix.HTML.Engine
        )

      :ok = File.write(index_path, "#{index_content}")
    end
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

        <%= Phoenix.HTML.raw styles || "" %>
        </style>
        <link rel="alternate" type="application/rss+xml" href="<%= feed_url %>" title="<%= blog_title %>">
      </head>
      <body>
        <div class="post-main">
          <h1><%= blog_title %> Posts</h1>
          <h2> Tagged <%= tag %> </h2>
          <ul>
            <%= for post <- posts do %>
              <li>
                <%= post.date |> DateTime.to_iso8601() |> String.slice( 0..9)%>
                <a href="../posts/<%= post.filename%>"> <%= post.title %> </a>
              </li>
            <% end %>
          </ul>
          <div>
          <h2> Other tags <h2>
            <%= for {tag, tag_path} <- tags do %>
              <a href="<%= tag_path %>"> <%= tag %> </a>
            <% end %>
          </div>
          <div>

          </div>

          <small>
          <div class="post-nav-container">
            <a class="post-nav-link" href="./feed.xml">RSS feed</a>
            <a href="../index.html" class="post-nav-link">Back to index...</a>
          </div>
        </small>
        </div>
      </body>
    </html>
    """
  end
end
