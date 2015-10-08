defmodule Mix.Tasks.Transmogrify do
  use Mix.Task

  @shortdoc "Convert a rails schema.rb file into a series of ecto models"

  def run([path, output| _] = args) do
    args |> IO.inspect

    schema = build_schema(path)
    [{mod, _}] = Code.compile_string(schema)

    mod.__info__(:functions)
    |> Enum.map(fn {fun, _} -> {fun, apply(mod, fun, [])} end)
    |> Enum.map(&build_file/1)
    |> Enum.map(&write_file(&1, output))
  end

  def build_file({fun, content}) do
    width  = Enum.map(content, fn [_, col | _] -> byte_size(col) end) |> Enum.max
    schema = content
    |> Enum.map(fn [type, col | rest] ->
      range = 0..(width - byte_size(col))
      buffer = for _ <- range , into: "", do: " "
      [type, {col, buffer} | rest]
    end)
    |> Enum.map(fn
      [:datetime | rest] ->
        [Ecto.Datetime | rest]
      other -> other
    end)
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

  def build_schema(path) do
    funs = path
    |> File.read!
    |> String.replace(~r/.+?(?=create_table)/s, "", global: false)
    |> String.replace(", force: true", "")
    |> String.replace("|t|", "")
    |> String.replace(~r/t\.(.+)/, "[:\\g{1}],")
    |> String.replace(~r/^.+add_index.+$/m, "")
    |> String.replace(~r/.+(\:[a-zA-Z]+) /, "[\\g{1},")
    |> String.replace(~r/end\n$/, "", global: false)
    |> String.replace("{", "%{  ")
    |> String.split("create_table", trim: true)
    |> Enum.map(&handle_module_names/1)

    [
      "defmodule Schema do\n",
      funs, "\n",
      "end"
    ]
    |> IO.iodata_to_binary
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
