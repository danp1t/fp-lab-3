defmodule Interpolation.Output do
  def print_results(results) do
    Enum.each(results, fn {algorithm, x, y} ->
      IO.puts("#{algorithm}: #{format_float(x)} #{format_float(y)}")
    end)
  end

  defp format_float(value) do
    if round(value) == value do
      Integer.to_string(round(value))
    else
      formatted = :io_lib.format("~.6f", [value]) |> List.to_string()
      formatted |> String.trim_trailing("0") |> String.trim_trailing(".")
    end
  end
end
