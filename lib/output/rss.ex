defmodule Zamrazac.Output.RSS do
  alias Zamrazac.Util
  alias Zamrazac.Input.Metadata

  @doc """
  Renders the RSS feed for a blog.
  """
  def generate_rss_feed(post_metadatas) do
    feed_path = Path.join(Util.get_output_directory(), "feed.xml")
    IO.puts("Writing feed to #{feed_path}")

    organized_posts =
      Enum.sort(post_metadatas, fn %Metadata{} = md1, %Metadata{} = md2 ->
        DateTime.to_unix(md1.date) > DateTime.to_unix(md2.date)
      end)

    {:safe, feed_content} =
      EEx.eval_string(
        rss_template(),
        [
          posts: organized_posts,
          blog_title: Util.get_blog_title(),
          blog_link: Util.get_blog_url(),
          blog_description: Util.get_blog_description(),
          feed_url: Util.get_feed_url()
        ],
        engine: Phoenix.HTML.Engine
      )

    :ok = File.write(feed_path, "#{feed_content}")
  end

  def rss_template() do
    """
    <?xml version="1.0" encoding="UTF-8" ?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
      <title><%= blog_title %></title>
      <link><%= blog_link %></link>
      <description><%= blog_description %></description>
      <atom:link href="<%= feed_url %>" rel="self" type="application/rss+xml" />
      <%= for post <- posts do %>
      <item>
        <title><%= post.title%></title>
        <link><%= post.slug%></link>
        <pubDate><%= post.date |> Timex.format!("{RFC1123}") %></pubDate>
        <guid isPermaLink="true"><%= post.slug %></guid>
      </item>
      <% end %>
      </channel>
    </rss>
    """
  end
end
