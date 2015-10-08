defmodule Mix.Tasks.Transmogrify do
  use Mix.Task

  @shortdoc "Convert a rails schema.rb file into a series of ecto models"

  def run([path, output| _] = args) do
    args |> IO.inspect

    schema = Transmogrifier.Input.read!(path)
    [{mod, _}] = Code.compile_string(schema)

    mod.__info__(:functions)
    |> Enum.map(fn {fun, _} -> {fun, apply(mod, fun, [])} end)
    |> Enum.map(&build_file/1)
    |> Enum.map(&write_file(&1, output))
  end

  def build_file({fun, content}) do
    width  = Enum.map(content, fn [_, col | _] -> byte_size(col) end) |> Enum.max
    schema = content
    |> Enum.map(&build_field/1)
    |> Enum.map(fn
      [type, {column, buffer}] ->
        "    field :#{column},#{buffer}#{inspect type}\n"
      [type, {column, buffer} | opts] ->
        "    field :#{column},#{buffer}#{inspect type}, #{inspect(opts)}\n"
      other -> raise other
    end)

    table = fun |> Atom.to_string
    name  = table |> Inflex.singularize

    content = [
      "defmodule #{name |> Mix.Utils.camelize} do\n\n",
      "  schema #{inspect(table)} do\n",
      schema,
      "  end\n\n",
      "end\n"
    ]
    |> IO.iodata_to_binary

    {name, content}
  end

  def build_field(row) do
    row
    |> determine_buffer
    |> special_case_datetime
    |> special_case_belongs_to
  end

  def determine_buffer([type, col | rest]) do
    buffer = for _ <- 0..(width - byte_size(col)) , into: "", do: " "
    [type, {col, buffer} | rest]
  end

  def special_case_datetime([:datetime | rest]), do: [Ecto.Datetime | rest]
  def special_case_datetime(other), do: other

  def special_case_belongs_to([_, col | rest] = original) do
    case String.replace(col, ~r/_id$/, "") do
      ^col -> original
      other -> [:belongs_to, other |> Inflex.singularize |> Mix.Utils.camelize | rest ]
    end
  end

  def handle_module_names(string) do
    Regex.replace(~r/"([A-Za-z_]+)" do(.+)end/s, string, fn
      _, table, content ->
        """
        def #{table} do
            [#{content}]
        end
        """
    end)
  end

  def write_file({name, content}, dir) do
    File.write!("#{dir}/#{name}.ex", content)
  end

end
