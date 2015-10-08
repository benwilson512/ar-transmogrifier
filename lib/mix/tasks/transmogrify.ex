defmodule Mix.Tasks.Transmogrify do
  use Mix.Task

  @shortdoc "Convert a rails schema.rb file into a series of ecto models"

  def run([module, path, output| _]) do
    path
    |> Transmogrifier.Input.build!
    |> Transmogrifier.Output.build
    |> Enum.map(&write_file(&1, output, module))
  end

  def write_file({name, content}, dir, module) do
    content = String.replace(content, "$module", module)
    File.write!("#{dir}/#{name}.ex", content)
  end

end
