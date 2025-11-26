defmodule Interpolation.Newton do
  @moduledoc """
  Реализация интерполяции полиномами Ньютона.
  Поддерживает выбор количества точек для интерполяции.
  """

  def interpolate(x, points, n) do
    if length(points) < n do
      :error
    else
      interpolation_points = select_interpolation_points(points, x, n)

      interpolation_points
      |> build_difference_table()
      |> evaluate_polynomial(x, interpolation_points)
    end
  end

  defp select_interpolation_points(points, target_x, n) do
    points
    |> Enum.sort_by(fn {px, _py} -> abs(px - target_x) end)
    |> Enum.take(n)
    |> Enum.sort_by(fn {px, _py} -> px end)
  end

  defp build_difference_table(points) do
    n = length(points)
    initial_table = for i <- 0..(n - 1), do: [elem(Enum.at(points, i), 1)]

    Enum.reduce(1..(n - 1), initial_table, &build_table_row(&1, &2, points, n))
  end

  defp build_table_row(j, table, points, n) do
    differences = calculate_differences(j, table, points, n)
    update_table_with_differences(differences, table, j)
  end

  defp calculate_differences(j, table, points, n) do
    for i <- 0..(n - 1 - j) do
      {xi, _} = Enum.at(points, i)
      {xij, _} = Enum.at(points, i + j)

      prev_val = Enum.at(Enum.at(table, i), j - 1)
      next_val = Enum.at(Enum.at(table, i + 1), j - 1)

      (next_val - prev_val) / (xij - xi)
    end
  end

  defp update_table_with_differences(differences, table, _) do
    differences
    |> Enum.with_index()
    |> Enum.reduce(table, fn {value, i}, acc ->
      List.update_at(acc, i, fn row -> row ++ [value] end)
    end)
  end

  defp evaluate_polynomial(table, x, points) do
    try do
      n = length(points)
      result = Enum.at(Enum.at(table, 0), 0)
      product = 1.0

      final_result =
        Enum.reduce(1..(n - 1), {result, product}, fn i, {acc, prod} ->
          {xi, _} = Enum.at(points, i - 1)
          new_product = prod * (x - xi)
          new_acc = acc + Enum.at(Enum.at(table, 0), i) * new_product
          {new_acc, new_product}
        end)

      {:ok, elem(final_result, 0)}
    rescue
      _ -> :error
    end
  end
end
