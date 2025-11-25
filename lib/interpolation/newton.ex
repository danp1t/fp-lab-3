defmodule Interpolation.Newton do
  def interpolate(x, points, n) do
    if length(points) < n do
      :error
    else
      interpolation_points = select_interpolation_points(points, x, n)
      calculate_newton(x, interpolation_points)
    end
  end

  defp select_interpolation_points(points, target_x, n) do
    points
    |> Enum.sort_by(fn {px, _py} -> abs(px - target_x) end)
    |> Enum.take(n)
    |> Enum.sort_by(fn {px, _py} -> px end)
  end

  defp calculate_newton(x, points) do
    try do
      n = length(points)
      table = build_difference_table(points)
      result = evaluate_polynomial(x, points, table)
      {:ok, result}
    rescue
      _ -> :error
    end
  end

  defp build_difference_table(points) do
    n = length(points)
    initial_table = for i <- 0..(n-1), do: [elem(Enum.at(points, i), 1)]

    Enum.reduce(1..(n-1), initial_table, fn j, table ->
      for i <- 0..(n-1-j) do
        {xi, _} = Enum.at(points, i)
        {xij, _} = Enum.at(points, i + j)

        prev_val = Enum.at(Enum.at(table, i), j-1)
        next_val = Enum.at(Enum.at(table, i+1), j-1)

        (next_val - prev_val) / (xij - xi)
      end
      |> Enum.with_index()
      |> Enum.reduce(table, fn {value, i}, acc ->
        List.update_at(acc, i, fn row -> row ++ [value] end)
      end)
    end)
  end

  defp evaluate_polynomial(x, points, table) do
    n = length(points)
    result = Enum.at(Enum.at(table, 0), 0)
    product = 1.0

    Enum.reduce(1..(n-1), result, fn i, acc ->
      {xi, _} = Enum.at(points, i-1)
      product = product * (x - xi)
      acc + Enum.at(Enum.at(table, 0), i) * product
    end)
  end
end
