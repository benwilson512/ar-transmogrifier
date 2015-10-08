defmodule Mix.Tasks.Transmogrify do
  use Mix.Task

  @shortdoc "Convert a rails schema.rb file into a series of ecto models"

  def run([path, output| _] = args) do
    args |> IO.inspect

    path
    |> Transmogrifier.Input.build!
    |> Transmogrifier.Output.build
    |> Enum.map(&write_file(&1, output))
  end

  def write_file({name, content}, dir) do
    File.write!("#{dir}/#{name}.ex", content)
  end

end
