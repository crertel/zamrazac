defmodule Zamrazac.Activities.GeneratePosts do
  @moduledoc """
  Function to convert blog posts from a directory.

  Conversion steps are:
  1. Walk the directory and collect the blog posts.
  2. For each blog post,
    2a. Pull out post metadata, remainder goes to 2b
    2b. Convert post from markdown into HTML
    2c. Walk HTML and collect image tags
    2d. For each image tag,
      2di. Download image into blog image directory for post
      2dii. Convert image to dithered 8x8 grayscale, keep original.
      2diii. Read converted image back as data URI
      2div. Replace img tag source with data URI
      2dv. Wrap image tag in anchor tag referencing stored full image.
      2dvi. Add comment for original source of image.
  3. Assemble index/archive view for posts from metadata.
  """

  alias Zamrazac.Util

  @doc """
  Function to crawl a posts directory and turn it into html, generate an index, and generate supporting image files.
  """
  def generate(posts_directory) do
    post_paths = get_post_paths(posts_directory)
    System.cmd("mkdir", ["-p", Util.get_output_directory()])
    System.cmd("mkdir", ["-p", Util.get_blog_output_image_directory()])
    System.cmd("mkdir", ["-p", Util.get_blog_output_post_directory()])
    posts = Enum.map(post_paths, &parse_post/1)
    sorted_posts = Enum.sort(posts, fn({a_metadata, _, _, _}, {b_metadata, _, _, _}) ->
        b_metadata[:date] >= a_metadata[:date]
      end)

    chunked_posts = Enum.chunk_every( [nil] ++ sorted_posts ++ [nil], 3, 1)
    Enum.map(chunked_posts, &write_post/1)

    post_metadatas = for {metadata,_,_,_} <- sorted_posts, into: [], do: metadata
    generate_post_index(post_metadatas)
    generate_rss_feed(post_metadatas)
  end

  def write_post([nil, post, next_post]) do
    {metadata, post_body_html, _post_path, post_html_path} = post
    {next_metadata, _, _, _} = next_post
    post_html_path = Path.join( Util.get_blog_output_post_directory(), post_html_path)
    IO.puts "Writing post #{metadata[:title]} to #{post_html_path}"
    write_post_file(post_html_path, metadata, post_body_html)
  end
  def write_post([prev_post, post, nil]) do
    {metadata, post_body_html, _post_path, post_html_path} = post
    {prev_metadata, _, _, _} = prev_post
    post_html_path = Path.join( Util.get_blog_output_post_directory(), post_html_path)
    IO.puts "Writing post #{metadata[:title]} to #{post_html_path}"
    write_post_file(post_html_path, metadata, post_body_html)
  end
  def write_post([prev_post, post, next_post]) do
    {metadata, post_body_html, _post_path, post_html_path} = post
    {prev_metadata, _, _, _} = prev_post
    {next_metadata, _, _, _} = next_post
    post_html_path = Path.join( Util.get_blog_output_post_directory(), post_html_path)
    IO.puts "Writing post #{metadata[:title]} to #{post_html_path}"
    write_post_file(post_html_path, metadata, post_body_html)
  end
  def write_post([post, nil]) do
  end

  @doc """
  Function that creates an index file given a pile of post metadata objects.
  """
  def generate_post_index(post_metadatas) do
    IO.inspect(post_metadatas, label: ">>>")
    index_path = Path.join(Util.get_output_directory(), "index.html")
    IO.puts "Writing index to #{index_path}"

    index_content = EEx.eval_string(index_template(),
    [
      posts: post_metadatas,
      blog_title: Util.get_blog_title(),
      feed_url: Util.get_feed_url(),
      styles: EExHTML.raw(Util.get_styles())
    ],
    engine: EExHTML.Engine
    )
    :ok = File.write(index_path, "#{index_content}" )
  end

  @doc """
  Crawls the posts directory and extracts the markdown files that look relevant.
  """
  def get_post_paths(posts_directory) do
    {:ok, files} = File.ls(posts_directory)

    Enum.filter(files, fn filename -> String.ends_with?(filename, ".md") end)
    |> Enum.map(fn filename -> Path.join(posts_directory, filename) end)
  end

  @doc """
  Parses a post into the metadata, body html, and post path.
  """
  def parse_post(post_path) do
    {:ok, contents} = File.read(post_path)
      ["", raw_metadata_text, raw_post_text] = String.split(contents, "---\n", parts: 3)
      post_basename = Path.basename(post_path,".md")
      post_html_filename = "#{post_basename}.html"
      metadata = parse_metadata(raw_metadata_text) ++
                [filename: post_html_filename,
                basename: post_basename,
                slug: "#{Util.get_blog_posts_root()}#{URI.encode(post_basename)}.html"]

      {:ok, post_html, []} = Earmark.as_html(raw_post_text)

      patched_html = patchup_images(metadata, post_html)
      {metadata, patched_html, post_path, post_html_filename}
  end

  #@doc """
  #Generates a post (html + images + metadata) and persists it.
  #"""
  #def generate_post(post_path) do
  #  {metadata, post_body_html, _post_path, post_html_path} = parse_post(post_path)
  #  post_html_path = Path.join( Util.get_blog_output_post_directory(), post_html_path)
  #  IO.puts "Writing post #{metadata[:title]} to #{post_html_path}"
  #  write_post_file(post_html_path, metadata, post_body_html)
  #  metadata
  #end

  @doc """
  Renders the actual post to an HTML file.
  """
  def write_post_file(path, metadata, post_html) do
    post_content = EEx.eval_string(post_template(),
    [
        blog_title: Util.get_blog_title(),
        post_date: metadata[:date] |> DateTime.to_iso8601() |> String.slice( 1..9),
        post_title: metadata[:title],
        post_author: metadata[:author],
        post_metadata: inspect(metadata, pretty: true),
        post_body: EExHTML.raw(post_html),
        feed_url: Util.get_feed_url(),
        styles: EExHTML.raw(Util.get_styles())
    ],
    engine: EExHTML.Engine
  )

    :ok = File.write( path, "#{post_content}")
  end

  @doc """
  Renders the RSS feed for a blog.
  """
  def generate_rss_feed(post_metadatas) do
    feed_path = Path.join(Util.get_output_directory(), "feed.xml")
    IO.puts "Writing feed to #{feed_path}"
    organized_posts = Enum.sort(post_metadatas, fn(md1, md2) -> DateTime.to_unix(md1[:date]) > DateTime.to_unix(md2[:date]) end)
    feed_content = EEx.eval_string(rss_template(),
    [
      posts: organized_posts,
      blog_title: Util.get_blog_title(),
      blog_link: Util.get_blog_url(),
      blog_description: Util.get_blog_description(),
      feed_url: Util.get_feed_url()
    ],
    engine: EExHTML.Engine
    )
    :ok  = File.write( feed_path, "#{feed_content}" )
  end

  @doc """
  Given a zamrazac-style post metadata string parses it out to a keyword list.
  """
  def parse_metadata(raw_metadata_string) do
    metadata_string = raw_metadata_string |> String.trim()

    metadata_string
    |> String.split("\n", trim: true)
    |> Enum.map(&String.split(&1, ":", parts: 2))
    |> Enum.map(fn [key, val] ->
      clean_key = String.trim(key)

      case clean_key do
        "tags" ->
          {String.to_atom(key), String.split(val) |> Enum.map(&String.downcase/1)}

        "date" ->
          {:ok, datetime, _} = DateTime.from_iso8601(String.trim(val))
          {String.to_atom(key), datetime}

        _ ->
          {String.to_atom(key), String.trim(val)}
      end
    end)
  end

  @doc """
  Given post metadata and markup, sets up image directory for the output and runs the routines that do image patchup.
  """
  def patchup_images(metadata, post_html) do
    dom = Floki.parse(post_html)
    image_storage_path = Path.join( Zamrazac.Util.get_blog_output_image_directory(), metadata[:basename])
    System.cmd("mkdir", ["-p", image_storage_path])
    patched_dom = Zamrazac.FlokiUtil.walk_dom(dom, image_storage_path)
    Floki.raw_html(patched_dom)
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
        <title><%= post_title %></title>
        <style>
        .post-main {
          width: 960px;
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

        <h1><%= blog_title %></h1>
        <h2><%=post_date %> -- <%= post_title %></h2>
        <h3><%= post_author %></h3>
        <%= post_body %>

        <small> <a href="../index.html">Back to index...</a> </small>
        </div>

      </body>
    </html>
    """
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
        <title><%= blog_title %></title>
        <style>
        .post-main {
          width: 960px;
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
                <%= post[:date] |> DateTime.to_iso8601() |> String.slice( 0..9)%>
                <a href="../posts/<%= post[:filename]%>"> <%= post[:title] %> </a>
              </li>
            <% end %>
          </ul>
        </div>
      </body>
    </html>
    """
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
        <title><%= post[:title]%></title>
        <link><%= post[:slug]%></link>
        <pubDate><%= post[:date] |> Timex.format!("{RFC1123}") %></pubDate>
        <guid isPermaLink="true"><%= post[:slug] %></guid>
      </item>
      <% end %>
      </channel>
    </rss>
    """
  end
end
