defmodule Zamrazac.FlokiUtil do
  @moduledoc """
  Tools for forcing Floki to do something it really doesn't want to do--transform HTML.
  """

  @doc """
  Function to walk a floki-style dom and patch it up.

  Here patching means discovering referenced images, downloading them, dithering them and encoding a smaller version,
  and finally wrapping the image tag in an anchor to the original image url.
  """
  def walk_dom({tag, attributes, children}, _image_storage_path), do: {tag, attributes, children}

  def walk_dom(elements, image_storage_path) when is_list(elements) do
    for element <- elements do
      case element do
        text when is_binary(text) ->
          text

        {"img", attributes, children} ->
          attrs = attributes_to_keywords(attributes)
          image_src = attrs[:src]
          #IO.inspect("Referenced image #{image_src}", limit: :infinity)

          {dithered_file_encoded, _temp_image_path, is_local} =
            convert_image(image_src, image_storage_path)

          patched_attrs =
            Keyword.put(attrs, :src, dithered_file_encoded) |> keywords_to_attributes()

          if is_local do
            {"img", patched_attrs, walk_dom(children, image_storage_path)}
          else
            {"a", [{"href", image_src}],
             [{"img", patched_attrs, walk_dom(children, image_storage_path)}]}
          end

        {tag, attributes, children} ->
          {tag, attributes, walk_dom(children, image_storage_path)}
      end
    end
  end

  @doc """
  Function to convert a keyword-style list made with string keys to having atomic keys.
  """
  def attributes_to_keywords(attributes) do
    attributes
    |> Enum.map(fn {key, val} ->
      {String.to_atom(key), val}
    end)
  end

  @doc """
  Function to convert a keyword-style list made with atomic keys to having string keys.
  """
  def keywords_to_attributes(keywords) do
    keywords
    |> Enum.map(fn {key, val} ->
      {Atom.to_string(key), val}
    end)
  end

  @doc """
  Function to do the image download and conversion and dithering given a url and a place to store the artifacts.
  """
  def convert_image(url, image_storage_path) do
    temp_image_name = Zamrazac.Util.shahexhash(url)
    temp_image_path = Path.join(image_storage_path, temp_image_name)
    uri = URI.parse(url)

    cond do
      uri.scheme in ["http", "https"] ->
        temp_dithered_image_path = "#{temp_image_path}_dithered.png"
        ^temp_image_path = maybe_download_image(temp_image_path, url, false)

        {dithered_file_encoded, ^temp_dithered_image_path} =
          maybe_dither_image(temp_dithered_image_path, temp_image_path)

        {dithered_file_encoded, temp_image_path, false}

      uri.scheme == "file" ->
        temp_dithered_image_path = "#{temp_image_path}_dithered.png"

        ^temp_image_path =
          maybe_download_image(temp_image_path, Path.expand(Path.join(uri.host, uri.path)), true)

        {dithered_file_encoded, ^temp_dithered_image_path} =
          maybe_dither_image(temp_dithered_image_path, temp_image_path)

        {dithered_file_encoded, temp_image_path, true}

      true ->
        #IO.inspect("\tFailed to locate image at  #{url}...", limit: :infinity)
        {"", "", true}
    end
  end

  @doc """
  Function to download an image from a url and save it somewhere if it isn't already there.
  """
  def maybe_download_image(image_path, url, is_local) do
    case File.exists?(image_path) do
      true ->
        #IO.inspect("\tReusing image #{image_path}...", limit: :infinity)
        image_path

      false ->
        if is_local do
          #IO.inspect("\tCopying local image from #{url} to #{image_path}...", limit: :infinity)
          System.cmd("cp", [url, image_path])
          image_path
        else
          #IO.inspect("\tDownloading image #{image_path}...", limit: :infinity)
          System.cmd("curl", [url, "-L", "-o", image_path])
          image_path
        end
    end
  end

  @doc """
  Function to convert an image to the dithered form if it doesn't already exist.
  """
  def maybe_dither_image(image_path, source_image_path) do
    case File.exists?(image_path) do
      true ->
        #IO.inspect("\tReusing dithered image #{image_path}...", limit: :infinity)
        nil

      false ->
        #IO.inspect("\tConverting dithered image #{image_path}...", limit: :infinity)

        System.cmd("convert", [
          source_image_path,
          "-colorspace",
          "Gray",
          "-ordered-dither",
          "8x8",
          image_path
        ])
    end

    dithered_file_encoded = Zamrazac.Util.get_file_as_data_uri(image_path, "image/png")
    {dithered_file_encoded, image_path}
  end
end
