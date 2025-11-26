defmodule Interpolation.Linear do
  def interpolate(x, points) do
    points = Enum.sort(points)

    Enum.reduce_while(points, nil, fn {x2, y2}, prev ->
      case prev do
        nil ->
          {:cont, {x2, y2}}

        {x1, y1} when x >= x1 and x <= x2 ->
          y = y1 + (y2 - y1) * (x - x1) / (x2 - x1)
          {:halt, {:ok, y}}

        _ ->
          {:cont, {x2, y2}}
      end
    end) || :error
  end
end
