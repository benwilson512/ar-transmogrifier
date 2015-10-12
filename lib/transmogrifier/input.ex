defmodule ARTransmogrifier.Input do
  alias ARTransmogrifier.Column

  def build!(path) do
    [{mod, _}] = path
    |> read!
    |> Code.compile_string

    mod.__info__(:functions)
    |> Enum.map(fn {fun, _} -> {fun |> Atom.to_string, apply(mod, fun, []) |> Enum.map(&Column.new/1)} end)
  end

  def read!(path) do
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
end
