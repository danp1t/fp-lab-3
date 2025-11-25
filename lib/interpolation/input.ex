defmodule Interpolation.Input do
  def read_loop(server_pid) do
    case IO.read(:line) do
      :eof -> GenServer.cast(server_pid, :eof)
      line ->
        line |> String.trim() |> process_line(server_pid)
        read_loop(server_pid)
    end
  end

  defp process_line("", _), do: :ok
  defp process_line(line, server_pid) do
    case String.split(line) do
      [x_str, y_str] ->
        with {x, ""} <- Float.parse(x_str),
             {y, ""} <- Float.parse(y_str) do
          GenServer.cast(server_pid, {:add_point, {x, y}})
        else
          _ -> IO.puts(:stderr, "Error: Invalid numbers")
        end
      _ -> IO.puts(:stderr, "Error: Need two numbers per line")
    end
  end
end
