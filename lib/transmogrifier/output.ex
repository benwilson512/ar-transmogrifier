defmodule Transmogrifier.Output do
  alias Transmogrifier.Column

  def build(schema) do
    has_many = build_has_many(schema)
    Enum.map(schema, &build_table_schema(&1, has_many))
  end

  def build_table_schema({table, columns}, has_many) do
    has_many_fields = has_many |> Map.get(table |> Inflex.singularize, [])

    schema = columns ++ has_many_fields
    |> Enum.group_by(&Map.get(&1, :type))
    |> Enum.map(fn {_, columns} ->
      width = Enum.map(columns, fn %{name: name} -> byte_size(name) end) |> Enum.max
      Enum.map(columns, &Column.to_string(&1, width))
    end)

    name = table |> Inflex.singularize

    content = [
      "defmodule #{name |> Mix.Utils.camelize} do\n",
      "  use Ecto.Model\n\n",
      "  schema #{inspect(table)} do\n",
      schema,
      "  end\n\n",
      "end\n"
    ]
    |> IO.iodata_to_binary

    {name, content}
  end

  def build_has_many(schema) do
    schema
    |> Enum.reduce(%{}, fn {table, columns}, acc ->
      columns
      |> Enum.filter_map(&match?(%{type: :belongs_to}, &1), &Map.get(&1, :name))
      |> Enum.reduce(acc, fn parent, acc ->
        col = %Column{type: :has_many, name: table, data_type: table |> Inflex.singularize |> Mix.Utils.camelize}
        Map.update(acc, parent, [], &[col | &1])
      end)
    end)
  end
end
