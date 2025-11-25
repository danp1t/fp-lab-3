defmodule Interpolation.Input do
  def read_loop(server_pid) do
    case IO.read(:line) do
      :eof ->
        GenServer.cast(server_pid, :eof)

      line ->
        line
        |> String.trim()
        |> process_line(server_pid)
        read_loop(server_pid)
    end
  end

  defp process_line("", _server_pid), do: :ok

  defp process_line(line, server_pid) do
    case parse_line(line) do
      {:ok, point} ->
        GenServer.cast(server_pid, {:add_point, point})
      {:error, reason} ->
        IO.puts(:stderr, "Error parsing line: #{reason}")
    end
  end

  defp parse_line(line) do
    case String.split(line, ~r/[\s\t;]+/) do
      [x_str, y_str] ->
        case {Float.parse(x_str), Float.parse(y_str)} do
          {{x, ""}, {y, ""}} -> {:ok, {x, y}}
          _ -> {:error, "Invalid number format"}
        end
      _ ->
        {:error, "Expected exactly two values per line"}
    end
  end
end
