defmodule Transmogrifier.Column do
  defstruct name: nil, data_type: nil, opts: [], type: :field
  alias Transmogrifier.Association

  def new([type, col | rest]) do
    %__MODULE__{data_type: type, name: col, opts: rest}
    |> handle_data_type
    |> handle_association
  end

  def handle_association(%{name: name} = field) do
    case String.replace(name, ~r/_id$/, "") do
      ^name -> field
      model ->
        model = model |> Inflex.singularize
        %{field | name: model, data_type: model |> Mix.Utils.camelize, type: :belongs_to}
    end
  end

  def handle_data_type(%{data_type: :datetime} = field), do: %{field | data_type: "Ecto.DateTime"}
  def handle_data_type(%{data_type: data_type} = field), do: %{field | data_type: ":#{data_type}"}

  def to_string(%{name: name, data_type: data_type, type: type, opts: opts}, width) do
    buffer = build_buffer(name, width)
    ["    #{type} :#{name},#{buffer}#{data_type}", handle_opts(type, opts), "\n"]
  end

  def handle_opts(_, []), do: ""
  def handle_opts(:belongs_to, _), do: ""
  def handle_opts(_, opts), do: [", #{inspect opts}"]

  defp build_buffer(name, width) do
    for _ <- 0..(width - byte_size(name)) , into: "", do: " "
  end
end
