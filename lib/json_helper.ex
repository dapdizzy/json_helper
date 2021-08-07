defmodule JsonHelper do
  @moduledoc """
  Documentation for JsonHelper.
  """

  @doc """
  Hello world.

  ## Examples

      iex> JsonHelper.hello()
      :world

  """
  def hello do
    :world
  end

  def sql_query_output_to_JSON(sql_query_filename, %{} = field_converters \\ %{},  field_names_replacement_map \\ nil) when sql_query_filename |> is_binary() do
    unless sql_query_filename |> File.exists? do
      raise "File #{sql_query_filename} does not exist"
    end
    <<_bom::binary-size(3), data::binary>> = sql_query_filename |> File.read!
    [title|data_lines] = data |> String.split("\r\n")
    title_indexed_map =
      for {value, index} <- title |> String.split("\t")
        |> Stream.filter(
          fn field_name ->
            !field_names_replacement_map || (field_names_replacement_map |> Map.has_key?(field_name))
          end)
        |> Stream.with_index(1), into: %{}, do: {index, field_names_replacement_map[value]}
    json = data_lines |> Stream.map(
      fn line ->
        for {value, index} <- line
          |> String.split("\t")
          |> Stream.with_index(1),
          into: %{} do
            field_name = title_indexed_map[index]
            converted_value =
              case field_converters[field_name] do
                function when function |> is_function(1) ->
                  function.(value)
                _ -> value
              end
            {field_name, converted_value}
          end
      end)
      |> Poison.encode!
    dir_name = sql_query_filename |> Path.dirname()
    ext = sql_query_filename |> Path.extname()
    base_name = sql_query_filename |> Path.basename(ext)
    save_to_filename = Path.join(dir_name, base_name <> "_RequestJSON" <> ext)
    result = save_to_filename |> File.write!(json, [:utf8])
    IO.puts "Saved JSON request to #{save_to_filename}"
    result
  end
end
