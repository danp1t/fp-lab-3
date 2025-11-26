defmodule Interpolation.Output do
  @moduledoc """
  Модуль для форматирования и вывода результатов интерполяции.
  """
  def print_results(results) do
    results
    |> Stream.each(fn {alg, x, y} ->
      IO.puts("#{alg}: #{format(x)} #{format(y)}")
    end)
    |> Stream.run()
  end

  defp format(num) do
    if num == round(num), do: Integer.to_string(round(num)), else: Float.to_string(num)
  end
end
