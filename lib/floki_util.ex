defmodule Zamrazac.FlokiUtil do
  @moduledoc """
  Tools for forcing Floki to do something it really doesn't want to do--transform HTML.
  """

  def walk_dom(elements) when is_list(elements) do
    for element <- elements do
      case element do
        text when is_binary(text) -> text
        {"img", attributes, children} ->
          attrs = attributes_to_keywords(attributes)
          image_src = attrs[:src]
          IO.puts("referenced image #{image_src}")
          {dithered_file_encoded, temp_image_path} = convert_image(image_src)
          patched_attrs = Keyword.put(attrs, :src, dithered_file_encoded) |> keywords_to_attributes()
          {"a", [{"href", image_src}],[{"img", patched_attrs, walk_dom(children) }]}
        {tag, attributes, children} ->
          {tag, attributes, walk_dom(children) }
      end
    end
  end
  def walk_dom({tag, attributes, children}), do: {tag, attributes, children}

  def attributes_to_keywords(attributes) do
    attributes
    |> Enum.map(fn({key, val}) ->
      {String.to_atom(key), val}
    end)
  end

  def keywords_to_attributes(keywords) do
    keywords
    |> Enum.map(fn({key, val}) ->
      {Atom.to_string(key), val}
    end)
  end

  def convert_image(url) do
    temp_image_name = Zamrazac.Util.get_temp_filename()
    temp_image_path = Path.join(Zamrazac.Util.get_blog_output_image_directory(), temp_image_name)
    temp_dithered_image_path = "#{temp_image_path}_dithered.png"
    System.cmd("curl", ["-o", temp_image_path, url] )
    System.cmd("convert", [temp_image_path, "-colorspace", "Gray", "-ordered-dither", "8x8", temp_dithered_image_path])
    dithered_file_encoded = Zamrazac.Util.get_file_as_data_uri(temp_dithered_image_path, "image/png")
    {dithered_file_encoded, temp_image_path}
  end
end
