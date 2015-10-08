defmodule Mix.Tasks.Transmogrify do
  use Mix.Task

  @shortdoc "Convert a rails schema.rb file into a series of ecto models"

  def run([path, output| _] = args) do
    args |> IO.inspect

    path
    |> File.read!
    |> String.replace(~r/.+?(?=create_table)/s, "", global: false)
    |> String.replace(", force: true", "")
    |> String.replace("|t|", "")
    |> String.replace("t.", "@field :")
    |> String.replace(~r/^.+add_index.+$/m, "")
    |> String.replace(~r/.+\:[a-zA-Z]+/, "\\g{0},")
    |> String.replace(~r/end\n$/, "", global: false)
    |> String.split("create_table", trim: true)
    |> Enum.map(&handle_module_names/1)
    |> Enum.each(&write_file(&1, output))
  end

  def handle_module_names(string) do
    table = case Regex.run(~r/.+"([A-Za-z_]+)" do/, string) do
      [_, table] -> table
      other      ->
        "ERRRRRORRRR" |> IO.puts
        string |> IO.inspect
        other |> IO.inspect
        raise "ERRRRRORRRR"
    end

    module_header = """
    defmodule #{Mix.Utils.camelize(table)} do
        Module.register_attribute(__MODULE__, :field, accumulate: true)
    """
    {table, String.replace(string, ~r/"([A-Za-z_]+)" do/, module_header)}
  end

  def write_file({name, content}, dir) do
    File.write!("#{dir}/#{name}.ex", content)
  end

end
