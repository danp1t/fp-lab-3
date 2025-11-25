defmodule Interpolation.Linear do
  def interpolate(x, points) do
    case find_segment(points, x) do
      {:ok, {x1, y1}, {x2, y2}} ->
        y = y1 + (y2 - y1) * (x - x1) / (x2 - x1)
        {:ok, y}
      :error ->
        :error
    end
  end

  defp find_segment([{x1, y1}, {x2, y2} | _], x) when x >= x1 and x <= x2 do
    {:ok, {x1, y1}, {x2, y2}}
  end

  defp find_segment([{x1, y1}, {x2, y2} | rest], x) when x < x1 do
    find_segment([{x1, y1} | rest], x)
  end

  defp find_segment([{x1, y1} | rest], x) when x > x1 do
    find_segment(rest, x)
  end

  defp find_segment([], _x), do: :error
  defp find_segment([_], _x), do: :error
end
